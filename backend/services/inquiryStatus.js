const { Op } = require('sequelize');
const Inquiry = require('../db/models/inquiry');
const Notification = require('../db/models/notification');
const Conversation = require('../db/models/conversation');
const { recalculateVendorStats } = require('./vendorStats');
const { blockDate, releaseDate } = require('./vendorAvailability');
const { notifyUser } = require('./notify');

const VALID_STATUSES = ['newInquiry', 'viewed', 'responded', 'quoted', 'booked', 'declined'];
const MAX_DECLINE_REASON = 300;

/// Thrown for anything the caller did wrong, so the route can map it to a
/// status code without knowing the rules itself.
class InquiryStatusError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

/**
 * Applies a vendor's answer to one of their inquiries.
 *
 * Extracted out of the route so it can be tested directly: this is the only
 * place that decides whether a wedding date is held on a vendor's calendar,
 * and getting it wrong either double-books them or leaves them blocked on a
 * day that is free.
 *
 * @param {object} vendor   the vendor row (mutated + saved when the calendar changes)
 * @param {object} inquiry  the inquiry row (mutated + saved)
 * @param {string} status   one of VALID_STATUSES
 * @param {string} [declineReason] required when status is 'declined'
 * @param {(inquiry: object) => Promise<string|null>} resolveWeddingDate
 */
async function applyInquiryStatus({
  vendor,
  inquiry,
  status,
  declineReason,
  resolveWeddingDate,
}) {
  if (!VALID_STATUSES.includes(status)) {
    throw new InquiryStatusError(400, 'Invalid status.');
  }

  if (status === 'declined') {
    const reason = typeof declineReason === 'string' ? declineReason.trim() : '';
    if (!reason) throw new InquiryStatusError(400, 'A decline reason is required.');
    if (reason.length > MAX_DECLINE_REASON) {
      throw new InquiryStatusError(400, `Decline reason must be ${MAX_DECLINE_REASON} characters or fewer.`);
    }
    inquiry.decline_reason = reason;
  }

  // Accepting holds the date on the vendor's calendar (the signal the AI
  // matcher filters on) and refuses to double-book the same day.
  if (status === 'booked') {
    const effectiveDate = await resolveWeddingDate(inquiry);
    if (effectiveDate) {
      const conflict = await Inquiry.findOne({
        where: {
          vendor_id: vendor.vendor_id,
          status: 'booked',
          wedding_date: effectiveDate,
          inquiry_id: { [Op.ne]: inquiry.inquiry_id },
        },
      });
      if (conflict) {
        throw new InquiryStatusError(409, 'You already have a confirmed booking on this date.');
      }
      if (!inquiry.wedding_date) inquiry.wedding_date = effectiveDate;
      // Idempotent by primary key — no read-modify-write, so two accepts
      // landing together can no longer lose one of each other's dates.
      await blockDate(vendor.vendor_id, effectiveDate);
    }
  }

  // Moving a confirmed booking back out of 'booked' — the vendor undoing an
  // accept — has to release the calendar hold, or they stay blocked on a date
  // that is free again. Mirrors the couple's cancel endpoint.
  const wasBooked = inquiry.status === 'booked';
  if (wasBooked && status !== 'booked' && inquiry.wedding_date) {
    await releaseDate(vendor.vendor_id, inquiry.wedding_date);
  }

  inquiry.status = status;
  if (['responded', 'quoted', 'booked', 'declined'].includes(status) && !inquiry.responded_at) {
    inquiry.responded_at = new Date();
  }
  await inquiry.save();

  // Response time, booking acceptance rate and completed-weddings count all
  // derive from inquiry status/timing.
  await recalculateVendorStats(vendor.vendor_id);

  let convoId = null;
  if (status === 'booked') {
    // A confirmed booking is exactly when a couple and vendor actually need
    // to talk — logistics, timing, final details. Creating the thread here
    // (rather than requiring either side to discover the messaging tab and
    // start one manually) is what lets the vendor route straight into a real
    // chat right after accepting instead of landing on an empty inbox.
    const [convo] = await Conversation.findOrCreate({
      where: { couple_user_id: inquiry.couple_user_id, vendor_id: vendor.vendor_id },
    });
    convoId = convo.convo_id;

    const bookingBody = inquiry.wedding_date
      ? `Your booking for ${inquiry.wedding_date} is confirmed.`
      : 'Your booking request has been confirmed.';
    await notifyUser(
      inquiry.couple_user_id,
      {
        type: 'booking_accepted',
        title: `${vendor.business_name} confirmed your booking!`,
        body: bookingBody,
        entity_id: vendor.vendor_id,
        entity_type: 'vendor',
      },
      {
        subject: `${vendor.business_name} confirmed your booking!`,
        heading: 'Booking confirmed',
        bodyHtml: bookingBody,
      },
    );
  } else if (status === 'declined') {
    await notifyUser(
      inquiry.couple_user_id,
      {
        type: 'booking_declined',
        title: `${vendor.business_name} declined your request`,
        body: inquiry.decline_reason,
        entity_id: vendor.vendor_id,
        entity_type: 'vendor',
      },
      {
        subject: `${vendor.business_name} declined your request`,
        heading: 'Booking request declined',
        bodyHtml: inquiry.decline_reason,
      },
    );
  } else if (wasBooked) {
    // The accept was undone. The couple was told "confirmed!" seconds ago and
    // leaving that in their inbox would be a straight lie.
    //
    // Newest single row rather than a blanket delete: entity_id on these is
    // the vendor, not this inquiry, so deleting by couple+vendor+type could
    // take out an older acceptance for a different booking that still stands.
    const staleAcceptance = await Notification.findOne({
      where: {
        user_id: inquiry.couple_user_id,
        type: 'booking_accepted',
        entity_id: vendor.vendor_id,
      },
      order: [['sent_at', 'DESC']],
    });
    if (staleAcceptance) await staleAcceptance.destroy();
  }

  return { inquiry, convoId };
}

module.exports = {
  applyInquiryStatus,
  InquiryStatusError,
  VALID_STATUSES,
  MAX_DECLINE_REASON,
};

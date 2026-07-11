const express = require('express');
const { Op, fn, col } = require('sequelize');
const Vendor = require('../db/models/vendor');
const VendorService = require('../db/models/vendorService');
const VendorMedia = require('../db/models/vendorMedia');
const VendorFeedback = require('../db/models/vendorFeedback');
const Inquiry = require('../db/models/inquiry');
const Expense = require('../db/models/expense');
const User = require('../db/models/user');
const CoupleProfile = require('../db/models/coupleProfile');
const Notification = require('../db/models/notification');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple, requireVendor } = require('../middleware/roles');
const { makeUploader, relativeUploadUrl } = require('../middleware/upload');
const { recalculateVendorStats, statsForVendorIds } = require('../services/vendorStats');

const router = express.Router();
const mediaUploader = makeUploader('vendors', { allowedMimePrefixes: ['image/', 'video/'], maxSizeMb: 25 });

// ── Serialization ────────────────────────────────────────────────────────────────

function serializeService(service) {
  return {
    service_id: service.service_id,
    vendor_id: service.vendor_id,
    title: service.title,
    description: service.description,
    price_min: Number(service.price_min),
    price_max: Number(service.price_max),
    unit: service.unit,
    is_active: service.is_active,
  };
}

function serializeMedia(media) {
  return {
    media_id: media.media_id,
    vendor_id: media.vendor_id,
    type: media.type,
    url: media.url,
    thumbnail_url: media.thumbnail_url,
    sort_order: media.sort_order,
    is_featured: media.is_featured,
  };
}

function serializeInquiry(inquiry, { coupleName = null, vendorName = null, hasFeedback = false } = {}) {
  return {
    inquiry_id: inquiry.inquiry_id,
    couple_id: inquiry.couple_user_id,
    vendor_id: inquiry.vendor_id,
    couple_name: coupleName,
    vendor_name: vendorName,
    status: inquiry.status,
    budget_range_min: inquiry.budget_range_min == null ? null : Number(inquiry.budget_range_min),
    budget_range_max: inquiry.budget_range_max == null ? null : Number(inquiry.budget_range_max),
    wedding_date: inquiry.wedding_date,
    message: inquiry.message,
    responded_at: inquiry.responded_at,
    decline_reason: inquiry.decline_reason,
    service_done_at: inquiry.service_done_at,
    rating_reminder_count: inquiry.rating_reminder_count,
    rating_reminder_last_sent_at: inquiry.rating_reminder_last_sent_at,
    has_feedback: hasFeedback,
    created_at: inquiry.created_at,
  };
}

async function serializeVendor(vendor, { includeDetail = false, statsInfo = null, services = null } = {}) {
  const stats = statsInfo ?? (await statsForVendorIds([vendor.vendor_id]))[vendor.vendor_id];

  const base = {
    vendor_id: vendor.vendor_id,
    user_id: vendor.user_id,
    business_name: vendor.business_name,
    description: vendor.description,
    category: vendor.category,
    location: vendor.location,
    latitude: vendor.latitude,
    longitude: vendor.longitude,
    tier: vendor.tier,
    verification_status: vendor.verification_status,
    is_featured: vendor.is_featured,
    style_tags: vendor.style_tags,
    logo_url: vendor.logo_url,
    phone: vendor.phone,
    website: vendor.website,
    whatsapp: vendor.whatsapp,
    contact_email: vendor.contact_email,
    address: vendor.address,
    instagram_handle: vendor.instagram_handle,
    blocked_dates: vendor.blocked_dates,
    // Public CRS + badges only — sourced from vendor_stats, never from raw
    // vendor_feedback (no comments, no reviewer identity ever leave that table).
    rating: stats.avg_star_rating,
    feedback_count: stats.feedback_count,
    composite_score: stats.crs_score,
    responds_in_minutes: stats.avg_response_time_minutes,
    weddings_completed: stats.completed_weddings_count,
    on_time_rate: stats.on_time_rate,
    recommend_rate: stats.recommend_rate,
    is_custom_entry: vendor.is_custom_entry,
  };

  // Every caller needs pricing (discovery filtering/sorting and the AI
  // matcher both read services[].price_min/price_max off the list response,
  // not just the single-vendor detail view) — either the pre-fetched bulk
  // `services` array from a list query, or a per-vendor lookup.
  if (services !== null) {
    base.services = services.map(serializeService);
  } else {
    const ownServices = await VendorService.findAll({ where: { vendor_id: vendor.vendor_id } });
    base.services = ownServices.map(serializeService);
  }

  if (includeDetail) {
    const media = await VendorMedia.findAll({ where: { vendor_id: vendor.vendor_id }, order: [['sort_order', 'ASC']] });
    base.media = media.map(serializeMedia);
  }

  return base;
}

// ── GET /api/vendors ────────────────────────────────────────────────────────────
// Any authenticated user (couple, vendor, or admin) can browse the directory.
router.get('/', verifyJwt, async (req, res) => {
  try {
    const { category, location, search, price_min, price_max, verified } = req.query;
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const where = { verification_status: { [Op.ne]: 'rejected' } };
    if (category) where.category = category;
    if (location) where.location = { [Op.like]: `%${location}%` };
    if (search) where.business_name = { [Op.like]: `%${search}%` };
    if (verified === 'true') where.verification_status = 'verified';

    let vendorIds = null;
    if (price_min || price_max) {
      const svcWhere = {};
      if (price_max) svcWhere.price_min = { [Op.lte]: Number(price_max) };
      if (price_min) svcWhere.price_max = { [Op.gte]: Number(price_min) };
      const matchingServices = await VendorService.findAll({ where: svcWhere, attributes: ['vendor_id'] });
      vendorIds = [...new Set(matchingServices.map((s) => s.vendor_id))];
      if (vendorIds.length === 0) return res.json({ vendors: [], total: 0 });
      where.vendor_id = { [Op.in]: vendorIds };
    }

    const { rows, count } = await Vendor.findAndCountAll({ where, limit, offset, order: [['created_at', 'DESC']] });
    const rowVendorIds = rows.map((v) => v.vendor_id);
    const [statsMap, allServices] = await Promise.all([
      statsForVendorIds(rowVendorIds),
      rowVendorIds.length
        ? VendorService.findAll({ where: { vendor_id: { [Op.in]: rowVendorIds } } })
        : [],
    ]);
    const servicesByVendor = {};
    for (const s of allServices) {
      (servicesByVendor[s.vendor_id] ??= []).push(s);
    }
    const vendors = await Promise.all(
      rows.map((v) => serializeVendor(v, {
        statsInfo: statsMap[v.vendor_id],
        services: servicesByVendor[v.vendor_id] ?? [],
      })),
    );
    res.json({ vendors, total: count });
  } catch (err) {
    console.error('List vendors error:', err.message);
    res.status(500).json({ error: 'Could not load vendors.' });
  }
});

// ── GET /api/vendors/me ─────────────────────────────────────────────────────────
router.get('/me', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ where: { user_id: req.user.user_id } });
    if (!vendor) return res.status(404).json({ error: 'No vendor profile yet.' });
    res.json({ vendor: await serializeVendor(vendor, { includeDetail: true }) });
  } catch (err) {
    console.error('Get own vendor profile error:', err.message);
    res.status(500).json({ error: 'Could not load profile.' });
  }
});

// ── PUT /api/vendors/me ─────────────────────────────────────────────────────────
// Upserts — this is also the vendor-onboarding submission endpoint.
router.put('/me', verifyJwt, requireVendor, async (req, res) => {
  const {
    business_name, description, category, location, latitude, longitude,
    style_tags, logo_url, phone, website, whatsapp, contact_email, address, instagram_handle,
  } = req.body;

  if (!business_name || typeof business_name !== 'string') {
    return res.status(400).json({ error: 'business_name is required.' });
  }
  if (!category || typeof category !== 'string') {
    return res.status(400).json({ error: 'category is required.' });
  }

  const allFields = {
    business_name, description, category, location, latitude, longitude,
    // style_tags is NOT NULL with a [] default — an explicit null (sent by
    // callers that don't set it, like the onboarding wizard) must be treated
    // as "not provided" rather than passed through, or the insert violates
    // the column's not-null constraint instead of falling back to the default.
    style_tags: style_tags ?? undefined,
    logo_url, phone, website, whatsapp, contact_email, address, instagram_handle,
  };
  const fields = Object.fromEntries(Object.entries(allFields).filter(([, v]) => v !== undefined));

  try {
    const [vendor, created] = await Vendor.findOrCreate({
      where: { user_id: req.user.user_id },
      defaults: { user_id: req.user.user_id, ...fields },
    });
    if (!created) {
      vendor.set(fields);
      await vendor.save();
    }
    res.json({ vendor: await serializeVendor(vendor, { includeDetail: true }) });
  } catch (err) {
    console.error('Save vendor profile error:', err.message);
    res.status(500).json({ error: 'Could not save profile.' });
  }
});

// ── Services ─────────────────────────────────────────────────────────────────────

async function ownVendorOr404(req, res) {
  const vendor = await Vendor.findOne({ where: { user_id: req.user.user_id } });
  if (!vendor) {
    res.status(404).json({ error: 'No vendor profile yet.' });
    return null;
  }
  return vendor;
}

// ── DELETE /api/vendors/me/logo ───────────────────────────────────────────────
router.delete('/me/logo', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    vendor.set({ logo_url: null });
    await vendor.save();
    res.json({ vendor: await serializeVendor(vendor, { includeDetail: true }) });
  } catch (err) {
    console.error('Remove vendor logo error:', err.message);
    res.status(500).json({ error: 'Could not remove logo.' });
  }
});

router.post('/me/services', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const { title, description, price_min, price_max, unit } = req.body;
    if (!title || price_min == null || price_max == null) {
      return res.status(400).json({ error: 'title, price_min, and price_max are required.' });
    }
    const service = await VendorService.create({
      vendor_id: vendor.vendor_id, title, description, price_min, price_max, unit: unit || 'package',
    });
    res.status(201).json({ service: serializeService(service) });
  } catch (err) {
    console.error('Create service error:', err.message);
    res.status(500).json({ error: 'Could not create service.' });
  }
});

router.put('/me/services/:id', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const service = await VendorService.findOne({ where: { service_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!service) return res.status(404).json({ error: 'Service not found.' });

    const allFields = { ...req.body };
    delete allFields.service_id;
    delete allFields.vendor_id;
    service.set(Object.fromEntries(Object.entries(allFields).filter(([, v]) => v !== undefined)));
    await service.save();
    res.json({ service: serializeService(service) });
  } catch (err) {
    console.error('Update service error:', err.message);
    res.status(500).json({ error: 'Could not update service.' });
  }
});

router.delete('/me/services/:id', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const deleted = await VendorService.destroy({ where: { service_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!deleted) return res.status(404).json({ error: 'Service not found.' });
    res.status(204).send();
  } catch (err) {
    console.error('Delete service error:', err.message);
    res.status(500).json({ error: 'Could not delete service.' });
  }
});

// ── Media ────────────────────────────────────────────────────────────────────────

router.post('/me/media', verifyJwt, requireVendor, mediaUploader.single('file'), async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });

    const type = req.file.mimetype.startsWith('video/') ? 'video' : 'image';
    const url = relativeUploadUrl('vendors', req.file.filename);
    const media = await VendorMedia.create({
      vendor_id: vendor.vendor_id,
      type,
      url,
      is_featured: req.body.is_featured === 'true' || req.body.is_featured === true,
    });
    res.status(201).json({ media: serializeMedia(media) });
  } catch (err) {
    console.error('Upload media error:', err.message);
    res.status(500).json({ error: 'Could not upload media.' });
  }
});

router.delete('/me/media/:id', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const deleted = await VendorMedia.destroy({ where: { media_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!deleted) return res.status(404).json({ error: 'Media not found.' });
    res.status(204).send();
  } catch (err) {
    console.error('Delete media error:', err.message);
    res.status(500).json({ error: 'Could not delete media.' });
  }
});

router.patch('/me/media/:id/featured', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const media = await VendorMedia.findOne({ where: { media_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!media) return res.status(404).json({ error: 'Media not found.' });
    media.is_featured = !media.is_featured;
    await media.save();
    res.json({ media: serializeMedia(media) });
  } catch (err) {
    console.error('Toggle media featured error:', err.message);
    res.status(500).json({ error: 'Could not update media.' });
  }
});

// A couple reporting a vendor's listing photo as inappropriate — this is what
// feeds the admin Content Moderation "Images" queue (GET /moderation/images
// only ever returns rows with status 'flagged').
router.post('/media/:id/report', verifyJwt, requireCouple, async (req, res) => {
  try {
    const media = await VendorMedia.findByPk(req.params.id);
    if (!media) return res.status(404).json({ error: 'Listing photo not found.' });
    const reason = typeof req.body.reason === 'string' ? req.body.reason.trim() : '';
    if (!reason) return res.status(400).json({ error: 'A reason is required to report this listing.' });

    media.status = 'flagged';
    media.flag_reason = reason;
    await media.save();
    res.json({ media: serializeMedia(media) });
  } catch (err) {
    console.error('Report media error:', err.message);
    res.status(500).json({ error: 'Could not report this listing.' });
  }
});

// ── Revenue ──────────────────────────────────────────────────────────────────────
// A real (correctly empty-until-linked) aggregate over Expense.vendor_id.
// Couples currently pick a vendor for an expense via free text, not a
// picker tied to vendor_id, so this will legitimately read as zero until
// that picker UI exists — deliberately deferred, not a bug.
router.get('/me/revenue', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;

    const now = new Date();
    const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const startOfYear = new Date(now.getFullYear(), 0, 1);

    const sumSince = async (since, until = null) => {
      const where = { vendor_id: vendor.vendor_id, created_at: { [Op.gte]: since } };
      if (until) where.created_at[Op.lt] = until;
      const result = await Expense.findOne({
        where,
        attributes: [[fn('SUM', col('amount')), 'total']],
        raw: true,
      });
      return Number(result?.total ?? 0);
    };

    const [thisMonth, lastMonth, yearToDate] = await Promise.all([
      sumSince(startOfThisMonth),
      sumSince(startOfLastMonth, startOfThisMonth),
      sumSince(startOfYear),
    ]);

    res.json({ this_month: thisMonth, last_month: lastMonth, year_to_date: yearToDate });
  } catch (err) {
    console.error('Vendor revenue error:', err.message);
    res.status(500).json({ error: 'Could not load revenue.' });
  }
});

// ── Blocked dates ────────────────────────────────────────────────────────────────

router.patch('/me/blocked-dates', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const { dates } = req.body;
    if (!Array.isArray(dates) || !dates.every((d) => typeof d === 'string')) {
      return res.status(400).json({ error: 'dates must be an array of date strings.' });
    }
    vendor.blocked_dates = dates;
    await vendor.save();
    res.json({ blocked_dates: vendor.blocked_dates });
  } catch (err) {
    console.error('Update blocked dates error:', err.message);
    res.status(500).json({ error: 'Could not update blocked dates.' });
  }
});

// ── Inquiries ────────────────────────────────────────────────────────────────────

router.get('/me/inquiries', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const inquiries = await Inquiry.findAll({ where: { vendor_id: vendor.vendor_id }, order: [['created_at', 'DESC']] });
    const coupleIds = [...new Set(inquiries.map((i) => i.couple_user_id))];
    const [couples, feedbackRows] = await Promise.all([
      coupleIds.length ? User.findAll({ where: { user_id: { [Op.in]: coupleIds } } }) : [],
      coupleIds.length
        ? VendorFeedback.findAll({ where: { vendor_id: vendor.vendor_id, couple_user_id: { [Op.in]: coupleIds } } })
        : [],
    ]);
    const nameById = Object.fromEntries(couples.map((u) => [u.user_id, u.name]));
    const feedbackCoupleIds = new Set(feedbackRows.map((f) => f.couple_user_id));
    res.json({
      inquiries: inquiries.map((i) => serializeInquiry(i, {
        coupleName: nameById[i.couple_user_id] ?? null,
        vendorName: vendor.business_name,
        hasFeedback: feedbackCoupleIds.has(i.couple_user_id),
      })),
    });
  } catch (err) {
    console.error('List inquiries error:', err.message);
    res.status(500).json({ error: 'Could not load inquiries.' });
  }
});

// A couple's own sent inquiries/bookings — the counterpart to the vendor's
// GET /me/inquiries above, which didn't exist until this feature (couples
// previously had no way to see their booking status or a decline reason).
router.get('/inquiries/mine', verifyJwt, requireCouple, async (req, res) => {
  try {
    const inquiries = await Inquiry.findAll({
      where: { couple_user_id: req.user.user_id },
      order: [['created_at', 'DESC']],
    });
    const vendorIds = [...new Set(inquiries.map((i) => i.vendor_id))];
    const [vendors, feedbackRows] = await Promise.all([
      vendorIds.length ? Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } }) : [],
      vendorIds.length
        ? VendorFeedback.findAll({ where: { couple_user_id: req.user.user_id, vendor_id: { [Op.in]: vendorIds } } })
        : [],
    ]);
    const vendorNameById = Object.fromEntries(vendors.map((v) => [v.vendor_id, v.business_name]));
    const feedbackVendorIds = new Set(feedbackRows.map((f) => f.vendor_id));
    res.json({
      inquiries: inquiries.map((i) => serializeInquiry(i, {
        vendorName: vendorNameById[i.vendor_id] ?? null,
        hasFeedback: feedbackVendorIds.has(i.vendor_id),
      })),
    });
  } catch (err) {
    console.error('List my bookings error:', err.message);
    res.status(500).json({ error: 'Could not load your bookings.' });
  }
});

// Resolves the wedding date to use for a booking: the inquiry's own date if
// it has one, otherwise the couple's on-file wedding date. Both columns are
// DATEONLY so this returns a plain 'YYYY-MM-DD' string (or null if neither
// is set).
async function resolveWeddingDate(inquiry) {
  if (inquiry.wedding_date) return inquiry.wedding_date;
  const profile = await CoupleProfile.findOne({ where: { user_id: inquiry.couple_user_id } });
  return profile?.wedding_date ?? null;
}

router.patch('/me/inquiries/:id', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const inquiry = await Inquiry.findOne({ where: { inquiry_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!inquiry) return res.status(404).json({ error: 'Inquiry not found.' });

    const { status } = req.body;
    const validStatuses = ['newInquiry', 'viewed', 'responded', 'quoted', 'booked', 'declined'];
    if (!validStatuses.includes(status)) return res.status(400).json({ error: 'Invalid status.' });

    if (status === 'declined') {
      const reason = typeof req.body.decline_reason === 'string' ? req.body.decline_reason.trim() : '';
      if (!reason) return res.status(400).json({ error: 'A decline reason is required.' });
      if (reason.length > 300) return res.status(400).json({ error: 'Decline reason must be 300 characters or fewer.' });
      inquiry.decline_reason = reason;
    }

    // Accepting a booking wires the real date into Vendor.blocked_dates (the
    // signal the AI matcher already penalizes against) and guards against
    // double-booking the same date via two still-pending inquiries.
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
          return res.status(409).json({ error: 'You already have a confirmed booking on this date.' });
        }
        if (!inquiry.wedding_date) inquiry.wedding_date = effectiveDate;
        const blocked = new Set(vendor.blocked_dates || []);
        if (!blocked.has(effectiveDate)) {
          vendor.blocked_dates = [...blocked, effectiveDate];
          await vendor.save();
        }
      }
    }

    inquiry.status = status;
    if (['responded', 'quoted', 'booked', 'declined'].includes(status) && !inquiry.responded_at) {
      inquiry.responded_at = new Date();
    }
    await inquiry.save();
    // Response time, booking acceptance rate, and completed-weddings count
    // all derive from inquiry status/timing.
    await recalculateVendorStats(vendor.vendor_id);

    if (status === 'booked') {
      await Notification.create({
        user_id: inquiry.couple_user_id,
        type: 'booking_accepted',
        title: `${vendor.business_name} confirmed your booking!`,
        body: inquiry.wedding_date
          ? `Your booking for ${inquiry.wedding_date} is confirmed.`
          : 'Your booking request has been confirmed.',
        entity_id: vendor.vendor_id,
        entity_type: 'vendor',
      });
    } else if (status === 'declined') {
      await Notification.create({
        user_id: inquiry.couple_user_id,
        type: 'booking_declined',
        title: `${vendor.business_name} declined your request`,
        body: inquiry.decline_reason,
        entity_id: vendor.vendor_id,
        entity_type: 'vendor',
      });
    }

    res.json({ inquiry: serializeInquiry(inquiry) });
  } catch (err) {
    console.error('Update inquiry error:', err.message);
    res.status(500).json({ error: 'Could not update inquiry.' });
  }
});

// Vendor marks a booked engagement's service as fulfilled — notifies the
// couple to leave (private) feedback. Capped at 2 reminders: the first sends
// the initial "please rate" prompt, the second is a final nudge in case the
// first was ignored; further calls are rejected once the couple has rated or
// the cap is reached.
router.post('/me/inquiries/:id/service-done', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const inquiry = await Inquiry.findOne({ where: { inquiry_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!inquiry) return res.status(404).json({ error: 'Inquiry not found.' });

    if (inquiry.status !== 'booked') {
      return res.status(409).json({ error: 'Only booked engagements can be marked as service done.' });
    }

    const existingFeedback = await VendorFeedback.findOne({
      where: { couple_user_id: inquiry.couple_user_id, vendor_id: vendor.vendor_id },
    });
    if (existingFeedback) {
      return res.status(409).json({ error: 'This couple has already rated you — no reminder needed.' });
    }

    if (inquiry.rating_reminder_count >= 2) {
      return res.status(409).json({ error: 'You’ve already sent the maximum of 2 rating reminders for this booking.' });
    }

    const isFirstReminder = inquiry.rating_reminder_count === 0;
    if (!inquiry.service_done_at) inquiry.service_done_at = new Date();
    inquiry.rating_reminder_count += 1;
    inquiry.rating_reminder_last_sent_at = new Date();
    await inquiry.save();
    // completed_weddings_count is now driven by service_done_at.
    await recalculateVendorStats(vendor.vendor_id);

    await Notification.create({
      user_id: inquiry.couple_user_id,
      type: 'rate_vendor',
      title: `How was ${vendor.business_name}?`,
      body: isFirstReminder
        ? `${vendor.business_name} marked your booking as complete. Share a quick private rating — it's never shown publicly.`
        : `Final reminder: rate your experience with ${vendor.business_name}. Your feedback stays private.`,
      entity_id: vendor.vendor_id,
      entity_type: 'vendor',
    });

    res.json({ inquiry: serializeInquiry(inquiry) });
  } catch (err) {
    console.error('Mark service done error:', err.message);
    res.status(500).json({ error: 'Could not mark service as done.' });
  }
});

router.post('/:id/inquiries', verifyJwt, requireCouple, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    const { message, budget_range_min, budget_range_max } = req.body;
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message is required.' });
    }

    // Normalize to a plain 'YYYY-MM-DD' (the client may send a full ISO
    // datetime), falling back to the couple's on-file wedding date so this
    // column — and downstream blocked-date/AI-availability checks — aren't
    // silently left null when the couple already has a date on record.
    let weddingDate = req.body.wedding_date ?? null;
    if (typeof weddingDate === 'string' && weddingDate.includes('T')) {
      weddingDate = weddingDate.split('T')[0];
    }
    if (!weddingDate) {
      const profile = await CoupleProfile.findOne({ where: { user_id: req.user.user_id } });
      weddingDate = profile?.wedding_date ?? null;
    }
    if (weddingDate && (vendor.blocked_dates || []).includes(weddingDate)) {
      return res.status(409).json({ error: 'This vendor isn’t available on your wedding date.' });
    }

    const inquiry = await Inquiry.create({
      couple_user_id: req.user.user_id,
      vendor_id: vendor.vendor_id,
      message,
      budget_range_min: budget_range_min ?? null,
      budget_range_max: budget_range_max ?? null,
      wedding_date: weddingDate,
    });
    res.status(201).json({ inquiry: serializeInquiry(inquiry) });
  } catch (err) {
    console.error('Send inquiry error:', err.message);
    res.status(500).json({ error: 'Could not send inquiry.' });
  }
});

// ── Feedback (private) ────────────────────────────────────────────────────────────
// Raw star + comment feedback is never public — only the vendor who owns it
// and admins may read it (enforced here, not just hidden in the UI). Every
// other couple only ever sees the aggregate CRS/badges from serializeVendor.

function serializeFeedback(feedback, { coupleName = null } = {}) {
  return {
    feedback_id: feedback.feedback_id,
    couple_id: feedback.couple_user_id,
    vendor_id: feedback.vendor_id,
    inquiry_id: feedback.inquiry_id,
    couple_name: coupleName,
    star_rating: feedback.star_rating,
    comment: feedback.comment,
    on_time: feedback.on_time,
    is_flagged: feedback.is_flagged,
    flag_reason: feedback.flag_reason,
    created_at: feedback.created_at,
  };
}

async function attachCoupleNames(feedbackRows) {
  const coupleIds = [...new Set(feedbackRows.map((f) => f.couple_user_id))];
  const couples = coupleIds.length
    ? await User.findAll({ where: { user_id: { [Op.in]: coupleIds } } })
    : [];
  const nameById = Object.fromEntries(couples.map((u) => [u.user_id, u.name]));
  return feedbackRows.map((f) => serializeFeedback(f, { coupleName: nameById[f.couple_user_id] ?? null }));
}

// Public: CRS + badge stats only, no comments, no reviewer identity.
router.get('/:vendorId/crs', verifyJwt, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.vendorId);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });
    const stats = (await statsForVendorIds([vendor.vendor_id]))[vendor.vendor_id];
    res.json({
      vendor_id: vendor.vendor_id,
      crs_score: stats.crs_score,
      rating: stats.avg_star_rating,
      feedback_count: stats.feedback_count,
      is_verified_business: vendor.verification_status === 'verified',
      responds_in_minutes: stats.avg_response_time_minutes,
      weddings_completed: stats.completed_weddings_count,
      on_time_rate: stats.on_time_rate,
      recommend_rate: stats.recommend_rate,
    });
  } catch (err) {
    console.error('Get vendor CRS error:', err.message);
    res.status(500).json({ error: 'Could not load vendor score.' });
  }
});

// Restricted: the vendor's own feedback, or an admin. 403 for everyone else,
// including other couples — there is no "public feedback list" endpoint.
router.get('/:vendorId/feedback', verifyJwt, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.vendorId);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    const isOwner = req.user.role === 'vendor' && vendor.user_id === req.user.user_id;
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'You do not have access to this vendor’s feedback.' });
    }

    const feedbackRows = await VendorFeedback.findAll({
      where: { vendor_id: vendor.vendor_id },
      order: [['created_at', 'DESC']],
    });
    res.json({ feedback: await attachCoupleNames(feedbackRows) });
  } catch (err) {
    console.error('List vendor feedback error:', err.message);
    res.status(500).json({ error: 'Could not load feedback.' });
  }
});

// Submit private feedback — only a couple with a booked inquiry for this
// vendor is eligible, and only once per couple-vendor pair (also enforced by
// a unique DB index as a second line of defense).
router.post('/:id/feedback', verifyJwt, requireCouple, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    const bookedInquiry = await Inquiry.findOne({
      where: {
        couple_user_id: req.user.user_id,
        vendor_id: vendor.vendor_id,
        status: 'booked',
        service_done_at: { [Op.ne]: null },
      },
      order: [['created_at', 'DESC']],
    });
    if (!bookedInquiry) {
      return res.status(403).json({ error: 'This vendor hasn’t marked your booking as complete yet.' });
    }

    const existing = await VendorFeedback.findOne({
      where: { couple_user_id: req.user.user_id, vendor_id: vendor.vendor_id },
    });
    if (existing) {
      return res.status(409).json({ error: 'You’ve already submitted feedback for this vendor.' });
    }

    const { star_rating, comment, on_time } = req.body;
    if (!Number.isInteger(star_rating) || star_rating < 1 || star_rating > 5) {
      return res.status(400).json({ error: 'star_rating must be an integer 1-5.' });
    }
    const validOnTime = ['yes', 'no', 'not_applicable'];
    if (on_time != null && !validOnTime.includes(on_time)) {
      return res.status(400).json({ error: 'on_time must be "yes", "no", or "not_applicable".' });
    }

    const feedback = await VendorFeedback.create({
      couple_user_id: req.user.user_id,
      vendor_id: vendor.vendor_id,
      inquiry_id: bookedInquiry.inquiry_id,
      star_rating,
      comment: comment || null,
      on_time: on_time ?? null,
    });
    await recalculateVendorStats(vendor.vendor_id);
    res.status(201).json({ feedback: serializeFeedback(feedback) });
  } catch (err) {
    console.error('Submit feedback error:', err.message);
    res.status(500).json({ error: 'Could not submit feedback.' });
  }
});

// ── GET /api/vendors/:id ────────────────────────────────────────────────────────
// Kept last so it doesn't shadow the more specific /me and /:id/... routes above.
router.get('/:id', verifyJwt, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });
    res.json({ vendor: await serializeVendor(vendor, { includeDetail: true }) });
  } catch (err) {
    console.error('Get vendor error:', err.message);
    res.status(500).json({ error: 'Could not load vendor.' });
  }
});

module.exports = router;

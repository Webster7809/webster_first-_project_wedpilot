const { Op } = require('sequelize');
const Vendor = require('../db/models/vendor');
const VendorFeedback = require('../db/models/vendorFeedback');
const VendorStats = require('../db/models/vendorStats');
const Inquiry = require('../db/models/inquiry');

const WEIGHTS = {
  rating: 0.40,
  weddings: 0.20,
  response: 0.10,
  acceptance: 0.10,
  onTime: 0.10,
  repeat: 0.05,
  verified: 0.05,
};

function clamp01(n) {
  return Math.min(1, Math.max(0, n));
}

/// Recomputes and persists vendor_stats for one vendor — the single source
/// of truth for the public CRS/badges. Called after any event that should
/// move the score: new feedback, admin flag/unflag, an inquiry status change
/// (covers response time + booking acceptance), and vendor verification
/// changes. Deliberately synchronous/inline (no queue infra exists in this
/// backend) — feedback/inquiry writes are low-traffic enough that this is
/// cheap relative to the request itself.
async function recalculateVendorStats(vendorId) {
  const vendor = await Vendor.findByPk(vendorId);
  if (!vendor) return null;

  const [feedbackRows, inquiries] = await Promise.all([
    VendorFeedback.findAll({ where: { vendor_id: vendorId, is_flagged: false }, raw: true }),
    Inquiry.findAll({ where: { vendor_id: vendorId }, raw: true }),
  ]);

  // ── Feedback-derived metrics ──────────────────────────────────────────────
  const feedbackCount = feedbackRows.length;
  const avgStarRating = feedbackCount
    ? Math.round((feedbackRows.reduce((sum, f) => sum + f.star_rating, 0) / feedbackCount) * 10) / 10
    : null;
  const recommendRate = feedbackCount
    ? feedbackRows.filter((f) => f.star_rating >= 4).length / feedbackCount
    : null;
  const onTimeAnswered = feedbackRows.filter((f) => f.on_time === 'yes' || f.on_time === 'no');
  const onTimeRate = onTimeAnswered.length
    ? onTimeAnswered.filter((f) => f.on_time === 'yes').length / onTimeAnswered.length
    : null;

  // ── Inquiry-derived metrics ───────────────────────────────────────────────
  const now = new Date();
  // Driven by the vendor explicitly marking service done, not by the wedding
  // date merely having passed — a more reliable "the job actually happened"
  // signal than an inferred date, and the only one that's populated for
  // every booking rather than only ones with a wedding_date on file.
  const completedWeddingsCount = inquiries.filter(
    (i) => i.status === 'booked' && i.service_done_at != null,
  ).length;

  const terminal = inquiries.filter((i) => i.status === 'booked' || i.status === 'declined');
  const bookingAcceptanceRate = terminal.length
    ? terminal.filter((i) => i.status === 'booked').length / terminal.length
    : null;

  const responded = inquiries.filter((i) => i.responded_at);
  const avgResponseTimeMinutes = responded.length
    ? responded.reduce((sum, i) => sum + (new Date(i.responded_at) - new Date(i.created_at)) / 60000, 0) / responded.length
    : null;

  const bookedByCouple = new Map();
  for (const i of inquiries) {
    if (i.status !== 'booked') continue;
    bookedByCouple.set(i.couple_user_id, (bookedByCouple.get(i.couple_user_id) ?? 0) + 1);
  }
  const repeatCustomerRate = bookedByCouple.size
    ? [...bookedByCouple.values()].filter((n) => n > 1).length / bookedByCouple.size
    : null;

  const isVerifiedBusiness = vendor.verification_status === 'verified';

  // ── Weighted CRS (0-100) ──────────────────────────────────────────────────
  const ratingNorm = avgStarRating != null ? avgStarRating / 5 : 0;
  const weddingsNorm = Math.min(completedWeddingsCount / 50, 1);
  // Same-day response earns full credit, tapering to zero credit at 24h+.
  const responseNorm = avgResponseTimeMinutes != null ? clamp01(1 - avgResponseTimeMinutes / 1440) : 0.5;
  const acceptanceNorm = bookingAcceptanceRate ?? 0.5;
  const onTimeNorm = onTimeRate ?? 0.5;
  const repeatNorm = repeatCustomerRate ?? 0;
  const verifiedNorm = isVerifiedBusiness ? 1 : 0;

  const crsScore = Math.round(
    (ratingNorm * WEIGHTS.rating +
      weddingsNorm * WEIGHTS.weddings +
      responseNorm * WEIGHTS.response +
      acceptanceNorm * WEIGHTS.acceptance +
      onTimeNorm * WEIGHTS.onTime +
      repeatNorm * WEIGHTS.repeat +
      verifiedNorm * WEIGHTS.verified) *
      100 * 100,
  ) / 100;

  const fields = {
    avg_star_rating: avgStarRating,
    feedback_count: feedbackCount,
    completed_weddings_count: completedWeddingsCount,
    avg_response_time_minutes: avgResponseTimeMinutes,
    booking_acceptance_rate: bookingAcceptanceRate,
    on_time_rate: onTimeRate,
    repeat_customer_rate: repeatCustomerRate,
    recommend_rate: recommendRate,
    is_verified_business: isVerifiedBusiness,
    crs_score: crsScore,
    last_calculated_at: now,
  };

  const [stats] = await VendorStats.findOrCreate({ where: { vendor_id: vendorId }, defaults: { vendor_id: vendorId, ...fields } });
  stats.set(fields);
  await stats.save();
  return stats;
}

const DEFAULT_STATS = {
  avg_star_rating: null,
  feedback_count: 0,
  completed_weddings_count: 0,
  avg_response_time_minutes: null,
  booking_acceptance_rate: null,
  on_time_rate: null,
  repeat_customer_rate: null,
  recommend_rate: null,
  is_verified_business: false,
  crs_score: 0,
  last_calculated_at: null,
};

/// Bulk read for list/detail serialization — mirrors the shape of the old
/// ratingAggForVendorIds. A vendor that's never had a stats recalculation
/// (no feedback, no inquiry activity yet) legitimately has no row — default
/// to honest zeros/nulls rather than fabricating a score.
async function statsForVendorIds(vendorIds) {
  if (vendorIds.length === 0) return {};
  const rows = await VendorStats.findAll({ where: { vendor_id: { [Op.in]: vendorIds } }, raw: true });
  const map = {};
  for (const id of vendorIds) map[id] = { ...DEFAULT_STATS };
  for (const row of rows) map[row.vendor_id] = row;
  return map;
}

module.exports = { recalculateVendorStats, statsForVendorIds };

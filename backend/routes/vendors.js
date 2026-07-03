const express = require('express');
const { Op, fn, col } = require('sequelize');
const Vendor = require('../db/models/vendor');
const VendorService = require('../db/models/vendorService');
const VendorMedia = require('../db/models/vendorMedia');
const Review = require('../db/models/review');
const Inquiry = require('../db/models/inquiry');
const Expense = require('../db/models/expense');
const User = require('../db/models/user');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple, requireVendor } = require('../middleware/roles');
const { makeUploader, relativeUploadUrl } = require('../middleware/upload');

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

function serializeInquiry(inquiry, { coupleName = null, vendorName = null } = {}) {
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
    created_at: inquiry.created_at,
  };
}

function serializeReview(review, { coupleName = null, coupleAvatarUrl = null } = {}) {
  return {
    review_id: review.review_id,
    couple_id: review.couple_user_id,
    vendor_id: review.vendor_id,
    couple_name: coupleName,
    couple_avatar_url: coupleAvatarUrl,
    rating: review.rating,
    title: review.title,
    body: review.body,
    status: review.status,
    photo_urls: review.photo_urls,
    published_at: review.published_at,
    created_at: review.created_at,
  };
}

// Computed at serialization time from real review data — not a stored/cached
// column, and not the fabricated formula the old frontend mock used.
function computeCompositeScore(avgRating, reviewCount) {
  const ratingNorm = (avgRating ?? 0) / 5;
  const volumeNorm = Math.min(reviewCount / 50, 1);
  return Math.round((ratingNorm * 0.7 + volumeNorm * 0.3) * 100 * 100) / 100;
}

async function ratingAggForVendorIds(vendorIds) {
  if (vendorIds.length === 0) return {};
  const rows = await Review.findAll({
    where: { vendor_id: { [Op.in]: vendorIds }, status: 'approved' },
    attributes: ['vendor_id', [fn('AVG', col('rating')), 'avg_rating'], [fn('COUNT', col('review_id')), 'review_count']],
    group: ['vendor_id'],
    raw: true,
  });
  const map = {};
  for (const row of rows) {
    map[row.vendor_id] = {
      rating: row.avg_rating == null ? null : Math.round(Number(row.avg_rating) * 10) / 10,
      reviewCount: Number(row.review_count),
    };
  }
  return map;
}

async function serializeVendor(vendor, { includeDetail = false, ratingInfo = null } = {}) {
  let rating = ratingInfo?.rating ?? null;
  let reviewCount = ratingInfo?.reviewCount ?? 0;
  if (ratingInfo === null) {
    const agg = await ratingAggForVendorIds([vendor.vendor_id]);
    rating = agg[vendor.vendor_id]?.rating ?? null;
    reviewCount = agg[vendor.vendor_id]?.reviewCount ?? 0;
  }

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
    rating,
    review_count: reviewCount,
    composite_score: computeCompositeScore(rating, reviewCount),
    is_custom_entry: vendor.is_custom_entry,
  };

  if (includeDetail) {
    const [services, media] = await Promise.all([
      VendorService.findAll({ where: { vendor_id: vendor.vendor_id } }),
      VendorMedia.findAll({ where: { vendor_id: vendor.vendor_id }, order: [['sort_order', 'ASC']] }),
    ]);
    base.services = services.map(serializeService);
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
    const ratingAgg = await ratingAggForVendorIds(rows.map((v) => v.vendor_id));
    const vendors = await Promise.all(
      rows.map((v) => serializeVendor(v, { ratingInfo: ratingAgg[v.vendor_id] ?? { rating: null, reviewCount: 0 } })),
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
    const couples = coupleIds.length
      ? await User.findAll({ where: { user_id: { [Op.in]: coupleIds } } })
      : [];
    const nameById = Object.fromEntries(couples.map((u) => [u.user_id, u.name]));
    res.json({
      inquiries: inquiries.map((i) => serializeInquiry(i, {
        coupleName: nameById[i.couple_user_id] ?? null,
        vendorName: vendor.business_name,
      })),
    });
  } catch (err) {
    console.error('List inquiries error:', err.message);
    res.status(500).json({ error: 'Could not load inquiries.' });
  }
});

router.patch('/me/inquiries/:id', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const inquiry = await Inquiry.findOne({ where: { inquiry_id: req.params.id, vendor_id: vendor.vendor_id } });
    if (!inquiry) return res.status(404).json({ error: 'Inquiry not found.' });

    const { status } = req.body;
    const validStatuses = ['newInquiry', 'viewed', 'responded', 'quoted', 'booked', 'declined'];
    if (!validStatuses.includes(status)) return res.status(400).json({ error: 'Invalid status.' });

    inquiry.status = status;
    if (['responded', 'quoted', 'booked', 'declined'].includes(status) && !inquiry.responded_at) {
      inquiry.responded_at = new Date();
    }
    await inquiry.save();
    res.json({ inquiry: serializeInquiry(inquiry) });
  } catch (err) {
    console.error('Update inquiry error:', err.message);
    res.status(500).json({ error: 'Could not update inquiry.' });
  }
});

router.post('/:id/inquiries', verifyJwt, requireCouple, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    const { message, budget_range_min, budget_range_max, wedding_date } = req.body;
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message is required.' });
    }

    const inquiry = await Inquiry.create({
      couple_user_id: req.user.user_id,
      vendor_id: vendor.vendor_id,
      message,
      budget_range_min: budget_range_min ?? null,
      budget_range_max: budget_range_max ?? null,
      wedding_date: wedding_date ?? null,
    });
    res.status(201).json({ inquiry: serializeInquiry(inquiry) });
  } catch (err) {
    console.error('Send inquiry error:', err.message);
    res.status(500).json({ error: 'Could not send inquiry.' });
  }
});

// ── Reviews ──────────────────────────────────────────────────────────────────────

router.get('/me/reviews', verifyJwt, requireVendor, async (req, res) => {
  try {
    const vendor = await ownVendorOr404(req, res);
    if (!vendor) return;
    const reviews = await Review.findAll({ where: { vendor_id: vendor.vendor_id }, order: [['created_at', 'DESC']] });
    res.json({ reviews: await attachCoupleInfo(reviews) });
  } catch (err) {
    console.error('List own reviews error:', err.message);
    res.status(500).json({ error: 'Could not load reviews.' });
  }
});

router.get('/:id/reviews', verifyJwt, async (req, res) => {
  try {
    const reviews = await Review.findAll({
      where: { vendor_id: req.params.id, status: 'approved' },
      order: [['created_at', 'DESC']],
    });
    res.json({ reviews: await attachCoupleInfo(reviews) });
  } catch (err) {
    console.error('List vendor reviews error:', err.message);
    res.status(500).json({ error: 'Could not load reviews.' });
  }
});

async function attachCoupleInfo(reviews) {
  const coupleIds = [...new Set(reviews.map((r) => r.couple_user_id))];
  const couples = coupleIds.length
    ? await User.findAll({ where: { user_id: { [Op.in]: coupleIds } } })
    : [];
  const byId = Object.fromEntries(couples.map((u) => [u.user_id, u]));
  return reviews.map((r) => serializeReview(r, {
    coupleName: byId[r.couple_user_id]?.name ?? null,
    coupleAvatarUrl: byId[r.couple_user_id]?.avatar_url ?? null,
  }));
}

router.post('/:id/reviews', verifyJwt, requireCouple, async (req, res) => {
  try {
    const vendor = await Vendor.findByPk(req.params.id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    const { rating, title, body, photo_urls } = req.body;
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'rating must be an integer 1-5.' });
    }
    if (!title || !body) return res.status(400).json({ error: 'title and body are required.' });

    const review = await Review.create({
      couple_user_id: req.user.user_id,
      vendor_id: vendor.vendor_id,
      rating,
      title,
      body,
      photo_urls: Array.isArray(photo_urls) ? photo_urls : [],
      published_at: new Date(),
    });
    res.status(201).json({ review: serializeReview(review) });
  } catch (err) {
    console.error('Submit review error:', err.message);
    res.status(500).json({ error: 'Could not submit review.' });
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

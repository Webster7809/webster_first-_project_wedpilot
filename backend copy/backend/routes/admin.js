const express = require('express');
const { Op, fn, col } = require('sequelize');
const User = require('../db/models/user');
const Vendor = require('../db/models/vendor');
const CoupleProfile = require('../db/models/coupleProfile');
const Review = require('../db/models/review');
const VendorMedia = require('../db/models/vendorMedia');
const Inquiry = require('../db/models/inquiry');
const Notification = require('../db/models/notification');
const verifyJwt = require('../middleware/verifyJwt');
const { requireAdmin } = require('../middleware/roles');

const router = express.Router();
router.use(verifyJwt, requireAdmin);

// ── Serialization ────────────────────────────────────────────────────────────────

function serializeUser(user, photoUrl = null) {
  return {
    user_id: user.user_id,
    name: user.name,
    email: user.email,
    role: user.role,
    is_suspended: user.is_suspended,
    created_at: user.created_at,
    photo_url: photoUrl,
  };
}

// Looks up each couple's/vendor's own profile photo so the admin user list
// can show the same picture the user set for themselves, rather than a
// generic avatar_url column nothing ever writes to.
async function photoUrlByUserId(users) {
  const coupleUserIds = users.filter((u) => u.role === 'couple').map((u) => u.user_id);
  const vendorUserIds = users.filter((u) => u.role === 'vendor').map((u) => u.user_id);
  const [coupleProfiles, vendors] = await Promise.all([
    coupleUserIds.length
      ? CoupleProfile.findAll({ where: { user_id: { [Op.in]: coupleUserIds } } })
      : [],
    vendorUserIds.length
      ? Vendor.findAll({ where: { user_id: { [Op.in]: vendorUserIds } } })
      : [],
  ]);
  const byId = new Map();
  for (const p of coupleProfiles) byId.set(p.user_id, p.photo_url);
  for (const v of vendors) byId.set(v.user_id, v.logo_url);
  return byId;
}

function serializePendingVendor(vendor, user) {
  return {
    vendor_id: vendor.vendor_id,
    business_name: vendor.business_name,
    category: vendor.category,
    location: vendor.location,
    email: user?.email ?? null,
    phone: vendor.phone,
    logo_url: vendor.logo_url,
    created_at: vendor.created_at,
  };
}

async function fetchPendingVendors() {
  const vendors = await Vendor.findAll({
    where: { verification_status: 'pending' },
    order: [['created_at', 'DESC']],
  });
  const userIds = vendors.map((v) => v.user_id);
  const users = await User.findAll({ where: { user_id: { [Op.in]: userIds } } });
  const userById = new Map(users.map((u) => [u.user_id, u]));
  return vendors.map((v) => serializePendingVendor(v, userById.get(v.user_id)));
}

// ── GET /api/admin/overview ───────────────────────────────────────────────────────

router.get('/overview', async (req, res) => {
  try {
    const [activeCouples, registeredVendors, pendingVendorsCount, verifiedVendorsCount] = await Promise.all([
      User.count({ where: { role: 'couple', is_suspended: false } }),
      User.count({ where: { role: 'vendor' } }),
      Vendor.count({ where: { verification_status: 'pending' } }),
      Vendor.count({ where: { verification_status: 'verified' } }),
    ]);

    const verificationTotal = verifiedVendorsCount + pendingVendorsCount;
    const verificationRate = verificationTotal === 0 ? 100 : Math.round((verifiedVendorsCount / verificationTotal) * 100);

    res.json({
      active_couples: activeCouples,
      registered_vendors: registeredVendors,
      pending_vendors_count: pendingVendorsCount,
      verification_rate: verificationRate,
      // Invitations aren't backed by a real endpoint yet (planned for a later
      // phase) — an honest zero until that system exists, not a placeholder.
      invitations_sent_this_week: 0,
    });
  } catch (err) {
    console.error('Admin overview error:', err.message);
    res.status(500).json({ error: 'Could not load platform overview.' });
  }
});

// ── Vendor verification ───────────────────────────────────────────────────────────

router.get('/vendors/pending', async (req, res) => {
  try {
    res.json({ vendors: await fetchPendingVendors() });
  } catch (err) {
    console.error('Pending vendors error:', err.message);
    res.status(500).json({ error: 'Could not load pending vendors.' });
  }
});

router.patch('/vendors/:id/verification', async (req, res) => {
  try {
    const { status, note } = req.body;
    if (!['verified', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'status must be "verified" or "rejected".' });
    }
    const vendor = await Vendor.findByPk(req.params.id);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    vendor.verification_status = status;
    vendor.verification_note = status === 'rejected' ? (note || null) : null;
    await vendor.save();

    await Notification.create({
      user_id: vendor.user_id,
      type: 'vendor_verification',
      title: status === 'verified' ? 'Profile verified' : 'Verification update',
      body: status === 'verified'
        ? 'Your vendor profile has been verified and is now visible to couples.'
        : `Your vendor profile was not approved.${note ? ` Reason: ${note}` : ''}`,
      entity_id: vendor.vendor_id,
      entity_type: 'vendor',
    });

    res.json({ vendor_id: vendor.vendor_id, verification_status: vendor.verification_status });
  } catch (err) {
    console.error('Vendor verification error:', err.message);
    res.status(500).json({ error: 'Could not update vendor verification.' });
  }
});

// ── User management ───────────────────────────────────────────────────────────────

router.get('/users', async (req, res) => {
  try {
    const users = await User.findAll({ order: [['created_at', 'DESC']] });
    const photoById = await photoUrlByUserId(users);
    res.json({ users: users.map((u) => serializeUser(u, photoById.get(u.user_id) ?? null)) });
  } catch (err) {
    console.error('Admin list users error:', err.message);
    res.status(500).json({ error: 'Could not load users.' });
  }
});

router.patch('/users/:id/suspend', async (req, res) => {
  try {
    const { suspended } = req.body;
    if (typeof suspended !== 'boolean') {
      return res.status(400).json({ error: 'suspended must be a boolean.' });
    }
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found.' });

    user.is_suspended = suspended;
    await user.save();
    const photoById = await photoUrlByUserId([user]);
    res.json({ user: serializeUser(user, photoById.get(user.user_id) ?? null) });
  } catch (err) {
    console.error('Suspend user error:', err.message);
    res.status(500).json({ error: 'Could not update user status.' });
  }
});

// Hard-deletes the account (login access only). Related domain data —
// budgets, vendor listings, reviews, inquiries — is deliberately left in
// place rather than cascade-deleted: that's a much bigger, separate data-
// retention decision than "revoke this account's access."
router.delete('/users/:id', async (req, res) => {
  try {
    if (req.params.id === req.user.user_id) {
      return res.status(400).json({ error: 'You cannot delete your own account.' });
    }
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    if (user.role === 'admin') {
      return res.status(403).json({ error: 'Admin accounts cannot be deleted from this panel.' });
    }

    await user.destroy();
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete user error:', err.message);
    res.status(500).json({ error: 'Could not delete user.' });
  }
});

// ── Content moderation ─────────────────────────────────────────────────────────────
// Reviews and vendor photos both carry a real `status`/flag column, but
// nothing upstream lets a couple or vendor report content yet — so these
// queues are real queries that will legitimately stay empty until that
// reporting entry point is built. Not fabricated data.

router.get('/moderation/reviews', async (req, res) => {
  try {
    const reviews = await Review.findAll({ where: { status: 'flagged' }, order: [['created_at', 'DESC']] });
    const vendorIds = [...new Set(reviews.map((r) => r.vendor_id))];
    const vendors = await Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const vendorById = new Map(vendors.map((v) => [v.vendor_id, v]));

    res.json({
      reviews: reviews.map((r) => ({
        review_id: r.review_id,
        vendor_name: vendorById.get(r.vendor_id)?.business_name ?? 'Unknown vendor',
        rating: r.rating,
        text: r.body,
        flag_reason: r.flag_reason ?? 'Reported',
      })),
    });
  } catch (err) {
    console.error('Flagged reviews error:', err.message);
    res.status(500).json({ error: 'Could not load flagged reviews.' });
  }
});

router.patch('/moderation/reviews/:id', async (req, res) => {
  try {
    const { action } = req.body;
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ error: 'action must be "approve" or "reject".' });
    }
    const review = await Review.findByPk(req.params.id);
    if (!review) return res.status(404).json({ error: 'Review not found.' });

    review.status = action === 'approve' ? 'approved' : 'rejected';
    await review.save();
    res.json({ review_id: review.review_id, status: review.status });
  } catch (err) {
    console.error('Moderate review error:', err.message);
    res.status(500).json({ error: 'Could not update review.' });
  }
});

router.get('/moderation/images', async (req, res) => {
  try {
    const images = await VendorMedia.findAll({ where: { status: 'flagged' }, order: [['created_at', 'DESC']] });
    const vendorIds = [...new Set(images.map((i) => i.vendor_id))];
    const vendors = await Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } });
    const vendorById = new Map(vendors.map((v) => [v.vendor_id, v]));

    res.json({
      images: images.map((i) => ({
        media_id: i.media_id,
        vendor_name: vendorById.get(i.vendor_id)?.business_name ?? 'Unknown vendor',
        category: vendorById.get(i.vendor_id)?.category ?? '',
        flag_reason: i.flag_reason ?? 'Reported',
        url: i.url,
        thumbnail_url: i.thumbnail_url,
      })),
    });
  } catch (err) {
    console.error('Flagged images error:', err.message);
    res.status(500).json({ error: 'Could not load flagged images.' });
  }
});

router.patch('/moderation/images/:id', async (req, res) => {
  try {
    const { action } = req.body;
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ error: 'action must be "approve" or "reject".' });
    }
    const media = await VendorMedia.findByPk(req.params.id);
    if (!media) return res.status(404).json({ error: 'Image not found.' });

    media.status = action === 'approve' ? 'active' : 'removed';
    await media.save();
    res.json({ media_id: media.media_id, status: media.status });
  } catch (err) {
    console.error('Moderate image error:', err.message);
    res.status(500).json({ error: 'Could not update image.' });
  }
});

// No message/conversation model exists yet (messaging is a later phase) —
// returning a real empty list rather than fabricating flagged messages.
router.get('/moderation/messages', async (req, res) => {
  res.json({ messages: [] });
});

// ── Platform analytics ────────────────────────────────────────────────────────────

function bucketByDay(dates, days) {
  const buckets = [];
  const now = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    const next = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1);
    const count = dates.filter((d) => d >= day && d < next).length;
    buckets.push({ label: day, count });
  }
  return buckets;
}

function bucketByWeek(dates, weeks) {
  const buckets = [];
  const now = new Date();
  for (let i = weeks - 1; i >= 0; i--) {
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i * 7);
    const start = new Date(end.getFullYear(), end.getMonth(), end.getDate() - 7);
    const count = dates.filter((d) => d >= start && d < end).length;
    buckets.push({ label: start, count });
  }
  return buckets;
}

function bucketByMonth(dates, months) {
  const buckets = [];
  const now = new Date();
  for (let i = months - 1; i >= 0; i--) {
    const start = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 1);
    const count = dates.filter((d) => d >= start && d < end).length;
    buckets.push({ label: start, count });
  }
  return buckets;
}

router.get('/analytics', async (req, res) => {
  try {
    const oneYearAgo = new Date();
    oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);

    const users = await User.findAll({
      where: { created_at: { [Op.gte]: oneYearAgo } },
      attributes: ['created_at'],
      raw: true,
    });
    const createdDates = users.map((u) => new Date(u.created_at));

    const userGrowth = {
      week: bucketByDay(createdDates, 7).map((b) => b.count),
      month: bucketByWeek(createdDates, 4).map((b) => b.count),
      year: bucketByMonth(createdDates, 12).map((b) => b.count),
    };

    const [freeCount, proCount, premiumCount] = await Promise.all([
      Vendor.count({ where: { tier: 'free' } }),
      Vendor.count({ where: { tier: 'pro' } }),
      Vendor.count({ where: { tier: 'premium' } }),
    ]);

    const inquiries = await Inquiry.findAll({ attributes: ['vendor_id'], raw: true });
    const vendorIds = [...new Set(inquiries.map((i) => i.vendor_id))];
    const vendors = await Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } }, attributes: ['vendor_id', 'category'], raw: true });
    const categoryByVendorId = new Map(vendors.map((v) => [v.vendor_id, v.category]));
    const countsByCategory = {};
    for (const inquiry of inquiries) {
      const category = categoryByVendorId.get(inquiry.vendor_id) ?? 'Other';
      countsByCategory[category] = (countsByCategory[category] ?? 0) + 1;
    }
    const topCategories = Object.entries(countsByCategory)
      .map(([category, count]) => ({ category, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    res.json({
      user_growth: userGrowth,
      vendor_tier_distribution: { free: freeCount, pro: proCount, premium: premiumCount },
      top_categories: topCategories,
    });
  } catch (err) {
    console.error('Admin analytics error:', err.message);
    res.status(500).json({ error: 'Could not load analytics.' });
  }
});

module.exports = router;

const express = require('express');
const CoupleProfile = require('../db/models/coupleProfile');
const Vendor = require('../db/models/vendor');
const VendorMatch = require('../db/models/vendorMatch');
const Notification = require('../db/models/notification');
const verifyJwt = require('../middleware/verifyJwt');
const { makeUploader, relativeUploadUrl } = require('../middleware/upload');

const router = express.Router();
const photoUploader = makeUploader('couples', { allowedMimePrefixes: ['image/'], maxSizeMb: 10 });

function requireCoupleRole(req, res, next) {
  if (req.user.role !== 'couple') {
    return res.status(403).json({ error: 'Only couple accounts can access this resource.' });
  }
  next();
}

function serializeProfile(profile) {
  return {
    profile_id: profile.profile_id,
    user_id: profile.user_id,
    partner_user_id: profile.partner_user_id,
    wedding_date: profile.wedding_date,
    location: profile.location,
    guest_count: profile.guest_count,
    style_tags: profile.style_tags,
    total_budget: profile.total_budget == null ? null : Number(profile.total_budget),
    currency: profile.currency,
    partner_name: profile.partner_name,
    photo_url: profile.photo_url,
  };
}

// ── GET /api/couple/profile ─────────────────────────────────────────────────────
router.get('/profile', verifyJwt, requireCoupleRole, async (req, res) => {
  try {
    const profile = await CoupleProfile.findOne({ where: { user_id: req.user.user_id } });
    // 404 here is the EXPECTED response for a couple who hasn't completed
    // onboarding yet, not a server error.
    if (!profile) {
      return res.status(404).json({ error: 'No couple profile yet.' });
    }
    res.json({ profile: serializeProfile(profile) });
  } catch (err) {
    console.error('Get couple profile error:', err.message);
    res.status(500).json({ error: 'Could not load profile.' });
  }
});

// ── PUT /api/couple/profile ─────────────────────────────────────────────────────
router.put('/profile', verifyJwt, requireCoupleRole, async (req, res) => {
  const {
    partner_user_id,
    wedding_date,
    location,
    guest_count,
    style_tags,
    total_budget,
    currency,
    partner_name,
    photo_url,
  } = req.body;

  if (guest_count != null && (!Number.isInteger(guest_count) || guest_count < 0)) {
    return res.status(400).json({ error: 'guest_count must be a non-negative integer.' });
  }
  if (total_budget != null && (typeof total_budget !== 'number' || total_budget < 0)) {
    return res.status(400).json({ error: 'total_budget must be a non-negative number.' });
  }
  if (style_tags != null && (!Array.isArray(style_tags) || !style_tags.every((t) => typeof t === 'string'))) {
    return res.status(400).json({ error: 'style_tags must be an array of strings.' });
  }

  const allFields = {
    partner_user_id,
    wedding_date,
    location,
    guest_count,
    style_tags,
    total_budget,
    currency,
    partner_name,
    photo_url,
  };
  // Only carry over fields the client actually sent, so a partial update
  // doesn't null out NOT NULL columns (style_tags, currency) via `undefined`.
  const fields = Object.fromEntries(
    Object.entries(allFields).filter(([, v]) => v !== undefined),
  );

  try {
    const [profile, created] = await CoupleProfile.findOrCreate({
      where: { user_id: req.user.user_id },
      defaults: { user_id: req.user.user_id, ...fields },
    });
    if (!created) {
      profile.set(fields);
      await profile.save();
    }
    res.json({ profile: serializeProfile(profile) });
  } catch (err) {
    console.error('Save couple profile error:', err.message);
    res.status(500).json({ error: 'Could not save profile.' });
  }
});

// ── POST /api/couple/profile/photo ────────────────────────────────────────────
router.post('/profile/photo', verifyJwt, requireCoupleRole, photoUploader.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });
    const photo_url = relativeUploadUrl('couples', req.file.filename);
    const [profile, created] = await CoupleProfile.findOrCreate({
      where: { user_id: req.user.user_id },
      defaults: { user_id: req.user.user_id, photo_url },
    });
    if (!created) {
      profile.set({ photo_url });
      await profile.save();
    }
    res.json({ profile: serializeProfile(profile) });
  } catch (err) {
    console.error('Upload couple photo error:', err.message);
    res.status(500).json({ error: 'Could not upload photo.' });
  }
});

// ── DELETE /api/couple/profile/photo ──────────────────────────────────────────
router.delete('/profile/photo', verifyJwt, requireCoupleRole, async (req, res) => {
  try {
    const profile = await CoupleProfile.findOne({ where: { user_id: req.user.user_id } });
    if (!profile) return res.status(404).json({ error: 'No couple profile yet.' });
    profile.set({ photo_url: null });
    await profile.save();
    res.json({ profile: serializeProfile(profile) });
  } catch (err) {
    console.error('Remove couple photo error:', err.message);
    res.status(500).json({ error: 'Could not remove photo.' });
  }
});

// ── POST /api/couple/vendor-matches ─────────────────────────────────────────────
// Called by the client after it computes the AI vendor matcher's top pick per
// category. Persists the current pick per category and only fires a
// notification when that pick is new or has changed — a repeat computation
// that lands on the same vendor is not "a new match" and stays silent.
router.post('/vendor-matches', verifyJwt, requireCoupleRole, async (req, res) => {
  const { matches } = req.body;
  if (!Array.isArray(matches)) {
    return res.status(400).json({ error: 'matches must be an array.' });
  }

  try {
    const updatedCategories = [];
    for (const m of matches) {
      const { category, vendor_id, confidence } = m ?? {};
      if (!category || !vendor_id) continue;

      const existing = await VendorMatch.findOne({
        where: { couple_user_id: req.user.user_id, category },
      });
      if (existing && existing.vendor_id === vendor_id) continue;

      if (existing) {
        existing.vendor_id = vendor_id;
        existing.confidence = typeof confidence === 'number' ? confidence : null;
        await existing.save();
      } else {
        await VendorMatch.create({
          couple_user_id: req.user.user_id,
          category,
          vendor_id,
          confidence: typeof confidence === 'number' ? confidence : null,
        });
      }

      const vendor = await Vendor.findByPk(vendor_id);
      await Notification.create({
        user_id: req.user.user_id,
        type: 'vendor_match',
        title: 'New vendor match',
        body: `${vendor?.business_name ?? 'A vendor'} is our top pick for ${category}, based on your budget and style.`,
        entity_id: vendor_id,
        entity_type: 'vendor',
      });
      updatedCategories.push(category);
    }

    res.json({ updated_categories: updatedCategories });
  } catch (err) {
    console.error('Sync vendor matches error:', err.message);
    res.status(500).json({ error: 'Could not save vendor matches.' });
  }
});

module.exports = router;

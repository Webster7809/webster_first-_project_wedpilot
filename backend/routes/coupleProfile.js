const express = require('express');
const CoupleProfile = require('../db/models/coupleProfile');
const verifyJwt = require('../middleware/verifyJwt');

const router = express.Router();

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

module.exports = router;

const express = require('express');
const SavedVendor = require('../db/models/savedVendor');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');

const router = express.Router();

// ── GET /api/wishlist ───────────────────────────────────────────────────────────
router.get('/', verifyJwt, requireCouple, async (req, res) => {
  try {
    const saved = await SavedVendor.findAll({ where: { couple_user_id: req.user.user_id } });
    res.json({ vendor_ids: saved.map((s) => s.vendor_id) });
  } catch (err) {
    console.error('List wishlist error:', err.message);
    res.status(500).json({ error: 'Could not load wishlist.' });
  }
});

// ── POST /api/wishlist ──────────────────────────────────────────────────────────
router.post('/', verifyJwt, requireCouple, async (req, res) => {
  try {
    const { vendor_id } = req.body;
    if (!vendor_id) return res.status(400).json({ error: 'vendor_id is required.' });
    await SavedVendor.findOrCreate({
      where: { couple_user_id: req.user.user_id, vendor_id },
      defaults: { couple_user_id: req.user.user_id, vendor_id },
    });
    res.status(201).json({ vendor_id });
  } catch (err) {
    console.error('Add to wishlist error:', err.message);
    res.status(500).json({ error: 'Could not save vendor.' });
  }
});

// ── DELETE /api/wishlist/:vendorId ──────────────────────────────────────────────
router.delete('/:vendorId', verifyJwt, requireCouple, async (req, res) => {
  try {
    await SavedVendor.destroy({
      where: { couple_user_id: req.user.user_id, vendor_id: req.params.vendorId },
    });
    res.status(204).send();
  } catch (err) {
    console.error('Remove from wishlist error:', err.message);
    res.status(500).json({ error: 'Could not remove vendor.' });
  }
});

module.exports = router;

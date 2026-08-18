const express = require('express');
const Notification = require('../db/models/notification');
const verifyJwt = require('../middleware/verifyJwt');

const router = express.Router();
router.use(verifyJwt);

function serialize(n) {
  return {
    notif_id: n.notif_id,
    user_id: n.user_id,
    type: n.type,
    title: n.title,
    body: n.body,
    entity_id: n.entity_id,
    entity_type: n.entity_type,
    is_read: n.is_read,
    sent_at: n.sent_at,
  };
}

router.get('/', async (req, res) => {
  try {
    const notifications = await Notification.findAll({
      where: { user_id: req.user.user_id },
      order: [['sent_at', 'DESC']],
      limit: 100,
    });
    res.json({ notifications: notifications.map(serialize) });
  } catch (err) {
    console.error('List notifications error:', err.message);
    res.status(500).json({ error: 'Could not load notifications.' });
  }
});

router.patch('/read-all', async (req, res) => {
  try {
    await Notification.update(
      { is_read: true },
      { where: { user_id: req.user.user_id, is_read: false } },
    );
    res.json({ marked: true });
  } catch (err) {
    console.error('Mark all notifications read error:', err.message);
    res.status(500).json({ error: 'Could not update notifications.' });
  }
});

router.patch('/:id/read', async (req, res) => {
  try {
    const notif = await Notification.findOne({
      where: { notif_id: req.params.id, user_id: req.user.user_id },
    });
    if (!notif) return res.status(404).json({ error: 'Notification not found.' });
    notif.is_read = true;
    await notif.save();
    res.json({ notification: serialize(notif) });
  } catch (err) {
    console.error('Mark notification read error:', err.message);
    res.status(500).json({ error: 'Could not update notification.' });
  }
});

// A notification row is never read by anyone but the user it belongs to
// (unlike an inquiry, nothing else references it), so this is a real delete
// rather than the hide-flag pattern used for bookings.
router.delete('/:id', async (req, res) => {
  try {
    const deleted = await Notification.destroy({
      where: { notif_id: req.params.id, user_id: req.user.user_id },
    });
    if (!deleted) return res.status(404).json({ error: 'Notification not found.' });
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete notification error:', err.message);
    res.status(500).json({ error: 'Could not delete this notification.' });
  }
});

// Clears every already-read notification in one action — the "tidy up" button
// next to "Mark all read". Unread ones are left alone; deleting something the
// couple hasn't seen yet would be surprising, and read-then-gone is the same
// two-step most apps use for this.
router.delete('/', async (req, res) => {
  try {
    const deleted = await Notification.destroy({
      where: { user_id: req.user.user_id, is_read: true },
    });
    res.json({ deletedCount: deleted });
  } catch (err) {
    console.error('Clear read notifications error:', err.message);
    res.status(500).json({ error: 'Could not clear notifications.' });
  }
});

module.exports = router;

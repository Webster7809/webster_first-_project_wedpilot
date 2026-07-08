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

module.exports = router;

const express = require('express');
const { Op } = require('sequelize');
const Conversation = require('../db/models/conversation');
const Message = require('../db/models/message');
const Vendor = require('../db/models/vendor');
const User = require('../db/models/user');
const CoupleProfile = require('../db/models/coupleProfile');
const Inquiry = require('../db/models/inquiry');
const verifyJwt = require('../middleware/verifyJwt');
const { notifyUser } = require('../services/notify');

const router = express.Router();
router.use(verifyJwt);

// ── Helpers ──────────────────────────────────────────────────────────────────────

async function resolveOwnVendorId(userId) {
  const vendor = await Vendor.findOne({ where: { user_id: userId } });
  return vendor ? vendor.vendor_id : null;
}

/// Returns the conversation if the current user is a participant, else null
/// (having already sent an appropriate response).
async function ownConversationOr404(req, res) {
  const convo = await Conversation.findByPk(req.params.id);
  if (!convo) {
    res.status(404).json({ error: 'Conversation not found.' });
    return null;
  }

  const isCouple = req.user.role === 'couple' && convo.couple_user_id === req.user.user_id;
  let isVendor = false;
  if (req.user.role === 'vendor') {
    const ownVendorId = await resolveOwnVendorId(req.user.user_id);
    isVendor = ownVendorId !== null && ownVendorId === convo.vendor_id;
  }
  if (!isCouple && !isVendor) {
    res.status(403).json({ error: 'You do not have access to this conversation.' });
    return null;
  }
  return convo;
}

async function serializeConversations(conversations) {
  if (conversations.length === 0) return [];

  const coupleUserIds = [...new Set(conversations.map((c) => c.couple_user_id))];
  const vendorIds = [...new Set(conversations.map((c) => c.vendor_id))];
  const convoIds = conversations.map((c) => c.convo_id);

  const [users, coupleProfiles, vendors, lastMessages, unreadCounts] = await Promise.all([
    User.findAll({ where: { user_id: { [Op.in]: coupleUserIds } } }),
    CoupleProfile.findAll({ where: { user_id: { [Op.in]: coupleUserIds } } }),
    Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } }),
    Message.findAll({
      where: { convo_id: { [Op.in]: convoIds } },
      order: [['created_at', 'DESC']],
    }),
    Message.findAll({
      where: { convo_id: { [Op.in]: convoIds }, is_read: false },
      attributes: ['convo_id', 'sender_user_id'],
      raw: true,
    }),
  ]);

  const userById = new Map(users.map((u) => [u.user_id, u]));
  const coupleProfileByUserId = new Map(coupleProfiles.map((p) => [p.user_id, p]));
  const vendorById = new Map(vendors.map((v) => [v.vendor_id, v]));

  const lastMessageByConvo = new Map();
  for (const m of lastMessages) {
    if (!lastMessageByConvo.has(m.convo_id)) lastMessageByConvo.set(m.convo_id, m);
  }

  const unreadByConvo = new Map();
  for (const row of unreadCounts) {
    unreadByConvo.set(row.convo_id, (unreadByConvo.get(row.convo_id) ?? []).concat(row.sender_user_id));
  }

  return conversations.map((c) => {
    const couple = userById.get(c.couple_user_id);
    const coupleProfile = coupleProfileByUserId.get(c.couple_user_id);
    const vendor = vendorById.get(c.vendor_id);
    const lastMessage = lastMessageByConvo.get(c.convo_id);
    return {
      convo_id: c.convo_id,
      couple_id: c.couple_user_id,
      vendor_id: c.vendor_id,
      couple_name: couple?.name ?? null,
      couple_avatar_url: coupleProfile?.photo_url ?? couple?.avatar_url ?? null,
      vendor_name: vendor?.business_name ?? null,
      vendor_avatar_url: vendor?.logo_url ?? null,
      last_message_text: lastMessage?.content ?? null,
      last_message_at: lastMessage?.created_at ?? null,
      _unreadSenderIds: unreadByConvo.get(c.convo_id) ?? [],
      is_archived: false,
    };
  });
}

// ── Conversations ────────────────────────────────────────────────────────────────

router.get('/conversations', async (req, res) => {
  try {
    let where;
    if (req.user.role === 'couple') {
      where = { couple_user_id: req.user.user_id };
    } else if (req.user.role === 'vendor') {
      const ownVendorId = await resolveOwnVendorId(req.user.user_id);
      if (!ownVendorId) return res.json({ conversations: [] });
      where = { vendor_id: ownVendorId };
    } else {
      return res.json({ conversations: [] });
    }

    const conversations = await Conversation.findAll({ where, order: [['updated_at', 'DESC']] });
    const serialized = await serializeConversations(conversations);

    // Resolve the "unread from the other person" count now that we know
    // which side of the conversation the current viewer is on.
    const result = serialized.map((c) => {
      const unreadCount = c._unreadSenderIds.filter((senderId) => senderId !== req.user.user_id).length;
      const { _unreadSenderIds, ...rest } = c;
      return { ...rest, unread_count: unreadCount };
    });

    res.json({ conversations: result });
  } catch (err) {
    console.error('List conversations error:', err.message);
    res.status(500).json({ error: 'Could not load conversations.' });
  }
});

async function findOrCreateConvoResponse(res, coupleUserId, vendorId) {
  const [convo] = await Conversation.findOrCreate({
    where: { couple_user_id: coupleUserId, vendor_id: vendorId },
  });
  const [serialized] = await serializeConversations([convo]);
  const { _unreadSenderIds, ...rest } = serialized;
  res.status(201).json({ conversation: { ...rest, unread_count: 0 } });
}

// Find-or-create a conversation between a couple and a vendor. Either side
// can start it — a couple messaging a vendor they're interested in (browsing
// a profile, before ever sending a formal inquiry) needs no relationship
// check, since discovery flows one direction in this app: couples find
// vendors, not the other way round. A vendor has no such discovery path, so
// their side is gated on an inquiry already existing between the two — the
// only legitimate way a vendor would ever have a couple's user id at all,
// and a free spam guard against messaging someone who never contacted them.
router.post('/conversations', async (req, res) => {
  try {
    if (req.user.role === 'couple') {
      const { vendor_id } = req.body;
      if (!vendor_id) return res.status(400).json({ error: 'vendor_id is required.' });

      const vendor = await Vendor.findByPk(vendor_id);
      if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

      return await findOrCreateConvoResponse(res, req.user.user_id, vendor_id);
    }

    if (req.user.role === 'vendor') {
      const { couple_user_id } = req.body;
      if (!couple_user_id) return res.status(400).json({ error: 'couple_user_id is required.' });

      const ownVendorId = await resolveOwnVendorId(req.user.user_id);
      if (!ownVendorId) return res.status(404).json({ error: 'Vendor profile not found.' });

      const hasInquiry = await Inquiry.findOne({
        where: { couple_user_id, vendor_id: ownVendorId },
      });
      if (!hasInquiry) {
        return res.status(403).json({ error: 'This couple has not contacted you yet.' });
      }

      return await findOrCreateConvoResponse(res, couple_user_id, ownVendorId);
    }

    res.status(403).json({ error: 'Only couples and vendors can start a conversation.' });
  } catch (err) {
    console.error('Create conversation error:', err.message);
    res.status(500).json({ error: 'Could not start conversation.' });
  }
});

// ── Messages ─────────────────────────────────────────────────────────────────────

function serializeMessage(m) {
  return {
    message_id: m.message_id,
    convo_id: m.convo_id,
    sender_id: m.sender_user_id,
    // A deleted message's content is never sent back to either side — the
    // row is only kept so timestamps/ordering/last-message-preview don't
    // shift for the other participant. The UI renders a tombstone off
    // is_deleted, not off an empty string.
    content: m.is_deleted ? null : m.content,
    is_deleted: m.is_deleted,
    type: m.type,
    is_read: m.is_read,
    edited_at: m.edited_at,
    sent_at: m.created_at,
  };
}

router.get('/conversations/:id/messages', async (req, res) => {
  try {
    const convo = await ownConversationOr404(req, res);
    if (!convo) return;

    const messages = await Message.findAll({ where: { convo_id: convo.convo_id }, order: [['created_at', 'ASC']] });

    // Mark anything the *other* participant sent as read now that this
    // participant has fetched the thread.
    await Message.update(
      { is_read: true },
      { where: { convo_id: convo.convo_id, sender_user_id: { [Op.ne]: req.user.user_id }, is_read: false } },
    );

    res.json({ messages: messages.map(serializeMessage) });
  } catch (err) {
    console.error('List messages error:', err.message);
    res.status(500).json({ error: 'Could not load messages.' });
  }
});

router.post('/conversations/:id/messages', async (req, res) => {
  try {
    const convo = await ownConversationOr404(req, res);
    if (!convo) return;

    const { content } = req.body;
    if (!content || !content.trim()) return res.status(400).json({ error: 'Message content is required.' });

    const message = await Message.create({
      convo_id: convo.convo_id,
      sender_user_id: req.user.user_id,
      content: content.trim(),
      type: 'text',
    });
    await convo.update({ updated_at: new Date() });

    // Notify whichever side of the conversation didn't just send this message.
    const senderIsCouple = req.user.user_id === convo.couple_user_id;
    const recipientUserId = senderIsCouple
      ? (await Vendor.findByPk(convo.vendor_id))?.user_id ?? null
      : convo.couple_user_id;
    if (recipientUserId) {
      const sender = await User.findByPk(req.user.user_id, { attributes: ['name'] });
      const messageTitle = `New message from ${sender?.name ?? 'someone'}`;
      const messagePreview = content.trim().slice(0, 140);
      await notifyUser(
        recipientUserId,
        {
          type: 'message',
          title: messageTitle,
          body: messagePreview,
          entity_id: convo.convo_id,
          entity_type: 'conversation',
        },
        { subject: messageTitle, heading: messageTitle, bodyHtml: messagePreview },
      );
    }

    res.status(201).json({ message: serializeMessage(message) });
  } catch (err) {
    console.error('Send message error:', err.message);
    res.status(500).json({ error: 'Could not send message.' });
  }
});

// Sender-only, like the equivalent WhatsApp action — content changes for
// both participants, and `edited_at` is what lets the UI mark it "(edited)"
// instead of pretending it always read this way.
router.patch('/conversations/:id/messages/:messageId', async (req, res) => {
  try {
    const convo = await ownConversationOr404(req, res);
    if (!convo) return;

    const message = await Message.findOne({
      where: { message_id: req.params.messageId, convo_id: convo.convo_id },
    });
    if (!message) return res.status(404).json({ error: 'Message not found.' });
    if (message.sender_user_id !== req.user.user_id) {
      return res.status(403).json({ error: 'You can only edit your own messages.' });
    }
    if (message.is_deleted) {
      return res.status(409).json({ error: 'This message was deleted.' });
    }

    const { content } = req.body;
    if (!content || !content.trim()) return res.status(400).json({ error: 'Message content is required.' });

    message.content = content.trim();
    message.edited_at = new Date();
    await message.save();

    res.json({ message: serializeMessage(message) });
  } catch (err) {
    console.error('Edit message error:', err.message);
    res.status(500).json({ error: 'Could not edit message.' });
  }
});

// Sender-only. Deletes for both ends at once (see serializeMessage) rather
// than a per-device "delete for me" — this app has one server-backed thread,
// not a local message store per device to diverge from it.
router.delete('/conversations/:id/messages/:messageId', async (req, res) => {
  try {
    const convo = await ownConversationOr404(req, res);
    if (!convo) return;

    const message = await Message.findOne({
      where: { message_id: req.params.messageId, convo_id: convo.convo_id },
    });
    if (!message) return res.status(404).json({ error: 'Message not found.' });
    if (message.sender_user_id !== req.user.user_id) {
      return res.status(403).json({ error: 'You can only delete your own messages.' });
    }

    message.is_deleted = true;
    message.content = '';
    await message.save();

    res.json({ message: serializeMessage(message) });
  } catch (err) {
    console.error('Delete message error:', err.message);
    res.status(500).json({ error: 'Could not delete message.' });
  }
});

module.exports = router;

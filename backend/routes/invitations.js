const crypto = require('crypto');
const express = require('express');
const { Op } = require('sequelize');
const Invitation = require('../db/models/invitation');
const Guest = require('../db/models/guest');
const RsvpResponse = require('../db/models/rsvpResponse');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');
const { makeUploader, relativeUploadUrl } = require('../middleware/upload');

const router = express.Router();
const photoUploader = makeUploader('invitations', { allowedMimePrefixes: ['image/'], maxSizeMb: 15 });

// ── Serialization ────────────────────────────────────────────────────────────────

// Flutter web has no path URL strategy configured, so it serves routes
// under a `#/` hash fragment (e.g. https://host:port/#/i/token) — the link
// must include that or a browser opening it directly will 404.
const PUBLIC_WEB_BASE_URL = process.env.PUBLIC_WEB_BASE_URL || 'http://localhost:8080';

function serializeInvitation(inv) {
  return {
    invitation_id: inv.invitation_id,
    couple_id: inv.couple_user_id,
    template_id: inv.template_id,
    title: inv.title,
    custom_data: inv.custom_data,
    share_token: inv.share_token,
    share_url: inv.status === 'published' ? `${PUBLIC_WEB_BASE_URL}/#/i/${inv.share_token}` : null,
    thumbnail_url: null,
    status: inv.status,
    view_count: inv.view_count,
    created_at: inv.created_at,
  };
}

function generateShareToken() {
  return crypto.randomBytes(8).toString('hex');
}

// ── Couple-owned CRUD ──────────────────────────────────────────────────────────────

router.get('/', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitations = await Invitation.findAll({
      where: { couple_user_id: req.user.user_id },
      order: [['created_at', 'DESC']],
    });
    res.json({ invitations: invitations.map(serializeInvitation) });
  } catch (err) {
    console.error('List invitations error:', err.message);
    res.status(500).json({ error: 'Could not load invitations.' });
  }
});

router.post('/', verifyJwt, requireCouple, async (req, res) => {
  try {
    const { template_id, title } = req.body;
    if (!template_id || !title) {
      return res.status(400).json({ error: 'template_id and title are required.' });
    }

    const invitation = await Invitation.create({
      couple_user_id: req.user.user_id,
      template_id,
      title,
      custom_data: {},
      share_token: generateShareToken(),
      status: 'draft',
    });
    res.status(201).json({ invitation: serializeInvitation(invitation) });
  } catch (err) {
    console.error('Create invitation error:', err.message);
    res.status(500).json({ error: 'Could not create invitation.' });
  }
});

router.patch('/:id', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { invitation_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const { custom_data } = req.body;
    if (custom_data && typeof custom_data === 'object') {
      invitation.custom_data = { ...invitation.custom_data, ...custom_data };
      if (typeof custom_data.coupleName === 'string' && custom_data.coupleName.trim()) {
        invitation.title = custom_data.coupleName.trim();
      }
    }
    await invitation.save();
    res.json({ invitation: serializeInvitation(invitation) });
  } catch (err) {
    console.error('Update invitation error:', err.message);
    res.status(500).json({ error: 'Could not update invitation.' });
  }
});

router.patch('/:id/publish', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { invitation_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    invitation.status = 'published';
    await invitation.save();
    res.json({ invitation: serializeInvitation(invitation) });
  } catch (err) {
    console.error('Publish invitation error:', err.message);
    res.status(500).json({ error: 'Could not publish invitation.' });
  }
});

router.post('/:id/photo', verifyJwt, requireCouple, photoUploader.single('file'), async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { invitation_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });
    if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });

    const url = relativeUploadUrl('invitations', req.file.filename);
    invitation.custom_data = { ...invitation.custom_data, backgroundImageUrl: url };
    await invitation.save();
    res.json({ invitation: serializeInvitation(invitation) });
  } catch (err) {
    console.error('Upload invitation photo error:', err.message);
    res.status(500).json({ error: 'Could not upload photo.' });
  }
});

// ── Public, unauthenticated guest-facing routes ────────────────────────────────────
// Reached via the app's own /i/:shareToken deep link — no Authorization header,
// since the guest opening the link has never logged in.

router.get('/public/:shareToken', async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { share_token: req.params.shareToken, status: 'published' },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    invitation.view_count += 1;
    await invitation.save();

    res.json({ invitation: serializeInvitation(invitation) });
  } catch (err) {
    console.error('Public invitation lookup error:', err.message);
    res.status(500).json({ error: 'Could not load invitation.' });
  }
});

// Reached via the app's own /g/:inviteToken deep link — a personal,
// per-guest link. Viewing never locks anything (messaging apps like
// WhatsApp/iMessage auto-fetch shared URLs to build a link preview, which
// would falsely burn a "locked on first view" design); only submitting an
// RSVP through this link locks it, enforced in the POST route below.
router.get('/public/guest/:inviteToken', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { invite_token: req.params.inviteToken } });
    if (!guest || !guest.invite_invitation_id) {
      return res.status(404).json({ error: 'Invitation not found.' });
    }

    const invitation = await Invitation.findOne({
      where: { invitation_id: guest.invite_invitation_id, status: 'published' },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    invitation.view_count += 1;
    await invitation.save();

    const existingRsvp = await RsvpResponse.findOne({ where: { guest_id: guest.guest_id } });

    res.json({
      invitation: serializeInvitation(invitation),
      guest: { guest_id: guest.guest_id, name: guest.name },
      already_responded: !!existingRsvp,
      existing_response: existingRsvp
        ? {
            attending: existingRsvp.attending,
            guest_count: existingRsvp.guest_count,
            message: existingRsvp.message,
          }
        : null,
    });
  } catch (err) {
    console.error('Public guest invitation lookup error:', err.message);
    res.status(500).json({ error: 'Could not load invitation.' });
  }
});

router.post('/public/guest/:inviteToken/rsvp', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { invite_token: req.params.inviteToken } });
    if (!guest || !guest.invite_invitation_id) {
      return res.status(404).json({ error: 'Invitation not found.' });
    }

    const invitation = await Invitation.findOne({
      where: { invitation_id: guest.invite_invitation_id, status: 'published' },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const existingRsvp = await RsvpResponse.findOne({ where: { guest_id: guest.guest_id } });
    if (existingRsvp) {
      return res.status(409).json({ error: 'You have already responded to this invitation.' });
    }

    const { attending, guestCount, message } = req.body;
    if (!['yes', 'no', 'maybe'].includes(attending)) {
      return res.status(400).json({ error: 'attending must be "yes", "no", or "maybe".' });
    }
    const count = Number(guestCount) || 1;

    await RsvpResponse.create({
      couple_user_id: invitation.couple_user_id,
      invitation_id: invitation.invitation_id,
      guest_id: guest.guest_id,
      attending,
      guest_count: attending === 'no' ? 0 : count,
      message: message && message.trim() ? message.trim() : null,
      responded_at: new Date(),
    });
    res.status(201).json({ submitted: true });
  } catch (err) {
    console.error('Public guest RSVP submit error:', err.message);
    res.status(500).json({ error: 'Could not submit RSVP.' });
  }
});

router.post('/public/:shareToken/rsvp', async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { share_token: req.params.shareToken, status: 'published' },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const { name, email, attending, guestCount, message } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ error: 'Name is required.' });
    if (!['yes', 'no', 'maybe'].includes(attending)) {
      return res.status(400).json({ error: 'attending must be "yes", "no", or "maybe".' });
    }
    const count = Number(guestCount) || 1;

    // Match an existing guest on the couple's list by name (case-insensitive)
    // so a guest who was pre-added still gets tracked as one person; otherwise
    // this RSVP creates a new ad-hoc guest entry.
    let guest = await Guest.findOne({
      where: { couple_user_id: invitation.couple_user_id, name: { [Op.like]: name.trim() } },
    });
    if (!guest) {
      guest = await Guest.create({
        couple_user_id: invitation.couple_user_id,
        name: name.trim(),
        email: email && email.trim() ? email.trim() : null,
        is_invited: true,
      });
    }

    const existingRsvp = await RsvpResponse.findOne({ where: { guest_id: guest.guest_id } });
    const values = {
      couple_user_id: invitation.couple_user_id,
      invitation_id: invitation.invitation_id,
      guest_id: guest.guest_id,
      attending,
      guest_count: attending === 'no' ? 0 : count,
      message: message && message.trim() ? message.trim() : null,
      responded_at: new Date(),
    };

    if (existingRsvp) {
      await existingRsvp.update(values);
    } else {
      await RsvpResponse.create(values);
    }
    res.status(201).json({ submitted: true });
  } catch (err) {
    console.error('Public RSVP submit error:', err.message);
    res.status(500).json({ error: 'Could not submit RSVP.' });
  }
});

module.exports = router;

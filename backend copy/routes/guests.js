const crypto = require('crypto');
const express = require('express');
const { Op } = require('sequelize');
const Guest = require('../db/models/guest');
const Invitation = require('../db/models/invitation');
const RsvpResponse = require('../db/models/rsvpResponse');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');

const router = express.Router();
router.use(verifyJwt, requireCouple);

// ── Serialization ────────────────────────────────────────────────────────────────

// Flutter web has no path URL strategy configured, so it serves routes
// under a `#/` hash fragment (e.g. https://host:port/#/g/token) — the link
// must include that or a browser opening it directly will 404.
const PUBLIC_WEB_BASE_URL = process.env.PUBLIC_WEB_BASE_URL || 'http://localhost:8080';

function serializeGuest(g) {
  return {
    guest_id: g.guest_id,
    couple_id: g.couple_user_id,
    name: g.name,
    phone: g.phone,
    email: g.email,
    whatsapp_number: g.whatsapp_number,
    relation: g.relation,
    is_invited: g.is_invited,
    invite_token: g.invite_token,
    invite_url: g.invite_token ? `${PUBLIC_WEB_BASE_URL}/#/g/${g.invite_token}` : null,
  };
}

function generateInviteToken() {
  return crypto.randomBytes(8).toString('hex');
}

function serializeRsvp(r, guestName) {
  return {
    rsvp_id: r.rsvp_id,
    invitation_id: r.invitation_id,
    guest_id: r.guest_id,
    guest_name: guestName,
    attending: r.attending,
    guest_count: r.guest_count,
    meal_preference: r.meal_preference,
    dietary_notes: r.dietary_notes,
    message: r.message,
    responded_at: r.responded_at,
  };
}

/// Batch-resolves each response's guest's current name.
async function serializeRsvps(responses) {
  if (responses.length === 0) return [];
  const guestIds = [...new Set(responses.map((r) => r.guest_id))];
  const guests = await Guest.findAll({ where: { guest_id: { [Op.in]: guestIds } } });
  const nameById = new Map(guests.map((g) => [g.guest_id, g.name]));
  return responses.map((r) => serializeRsvp(r, nameById.get(r.guest_id) ?? null));
}

function validateGuestInput({ name, email, phone }) {
  if (!name || !name.trim()) return 'Guest name is required.';
  if (name.trim().length < 2) return 'Name must be at least 2 characters.';
  if (email && email.trim() && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) {
    return 'Enter a valid email address.';
  }
  if (phone && phone.trim() && phone.trim().length < 7) {
    return 'Enter a valid phone number (at least 7 digits).';
  }
  return null;
}

// ── Guests ─────────────────────────────────────────────────────────────────────

router.get('/', async (req, res) => {
  try {
    const guests = await Guest.findAll({ where: { couple_user_id: req.user.user_id }, order: [['created_at', 'ASC']] });
    res.json({ guests: guests.map(serializeGuest) });
  } catch (err) {
    console.error('List guests error:', err.message);
    res.status(500).json({ error: 'Could not load guests.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const { name, email, phone, relation } = req.body;
    const error = validateGuestInput({ name, email, phone });
    if (error) return res.status(400).json({ error });

    const duplicate = await Guest.findOne({
      where: { couple_user_id: req.user.user_id, name: { [Op.like]: name.trim() } },
    });
    if (duplicate) return res.status(409).json({ error: `A guest named "${name.trim()}" already exists.` });

    const guest = await Guest.create({
      couple_user_id: req.user.user_id,
      name: name.trim(),
      email: email && email.trim() ? email.trim() : null,
      phone: phone && phone.trim() ? phone.trim() : null,
      relation: relation && relation.trim() ? relation.trim() : null,
      is_invited: true,
    });
    res.status(201).json({ guest: serializeGuest(guest) });
  } catch (err) {
    console.error('Create guest error:', err.message);
    res.status(500).json({ error: 'Could not add guest.' });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { guest_id: req.params.id, couple_user_id: req.user.user_id } });
    if (!guest) return res.status(404).json({ error: 'Guest not found.' });

    const { name, email, phone, relation } = req.body;
    const error = validateGuestInput({ name, email, phone });
    if (error) return res.status(400).json({ error });

    const duplicate = await Guest.findOne({
      where: {
        couple_user_id: req.user.user_id,
        name: { [Op.like]: name.trim() },
        guest_id: { [Op.ne]: guest.guest_id },
      },
    });
    if (duplicate) return res.status(409).json({ error: `Another guest named "${name.trim()}" already exists.` });

    guest.name = name.trim();
    guest.email = email && email.trim() ? email.trim() : null;
    guest.phone = phone && phone.trim() ? phone.trim() : null;
    guest.relation = relation && relation.trim() ? relation.trim() : null;
    await guest.save();
    res.json({ guest: serializeGuest(guest) });
  } catch (err) {
    console.error('Edit guest error:', err.message);
    res.status(500).json({ error: 'Could not update guest.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { guest_id: req.params.id, couple_user_id: req.user.user_id } });
    if (!guest) return res.status(404).json({ error: 'Guest not found.' });

    await RsvpResponse.destroy({ where: { guest_id: guest.guest_id } });
    await guest.destroy();
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete guest error:', err.message);
    res.status(500).json({ error: 'Could not delete guest.' });
  }
});

router.patch('/:id/toggle-invited', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { guest_id: req.params.id, couple_user_id: req.user.user_id } });
    if (!guest) return res.status(404).json({ error: 'Guest not found.' });

    guest.is_invited = !guest.is_invited;
    await guest.save();
    res.json({ guest: serializeGuest(guest) });
  } catch (err) {
    console.error('Toggle invited error:', err.message);
    res.status(500).json({ error: 'Could not update guest.' });
  }
});

// Gets (lazily generating) this guest's personal, single-use invite link for
// the given invitation. Re-calling with a different invitationId simply
// repoints the same link rather than invalidating it.
router.post('/:id/invite-link', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { guest_id: req.params.id, couple_user_id: req.user.user_id } });
    if (!guest) return res.status(404).json({ error: 'Guest not found.' });

    const { invitationId } = req.body;
    if (!invitationId) return res.status(400).json({ error: 'invitationId is required.' });

    const invitation = await Invitation.findOne({
      where: { invitation_id: invitationId, couple_user_id: req.user.user_id },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    if (!guest.invite_token) guest.invite_token = generateInviteToken();
    guest.invite_invitation_id = invitationId;
    await guest.save();
    res.json({ guest: serializeGuest(guest) });
  } catch (err) {
    console.error('Create guest invite link error:', err.message);
    res.status(500).json({ error: 'Could not create invite link.' });
  }
});

// ── RSVP responses ───────────────────────────────────────────────────────────────

router.get('/responses', async (req, res) => {
  try {
    const responses = await RsvpResponse.findAll({
      where: { couple_user_id: req.user.user_id },
      order: [['responded_at', 'DESC']],
    });
    res.json({ responses: await serializeRsvps(responses) });
  } catch (err) {
    console.error('List RSVP responses error:', err.message);
    res.status(500).json({ error: 'Could not load RSVP responses.' });
  }
});

// Records or replaces the RSVP for one of the couple's own guests (manual
// entry from the guest-list screen, as opposed to the public share-link flow).
router.post('/:id/rsvp', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { guest_id: req.params.id, couple_user_id: req.user.user_id } });
    if (!guest) return res.status(404).json({ error: 'Guest not found.' });

    const { attending, guestCount, mealPreference, dietaryNotes, message, invitationId } = req.body;
    if (!['yes', 'no', 'maybe'].includes(attending)) {
      return res.status(400).json({ error: 'attending must be "yes", "no", or "maybe".' });
    }
    const count = Number(guestCount) || 0;
    if (attending === 'yes' && count < 1) {
      return res.status(400).json({ error: 'Attending guest count must be at least 1.' });
    }
    if (count > 20) return res.status(400).json({ error: 'Guest count seems unrealistically high (max 20).' });
    if (count < 0) return res.status(400).json({ error: 'Guest count cannot be negative.' });

    const existing = await RsvpResponse.findOne({ where: { guest_id: guest.guest_id } });
    const values = {
      couple_user_id: req.user.user_id,
      invitation_id: invitationId || existing?.invitation_id || null,
      guest_id: guest.guest_id,
      attending,
      guest_count: attending === 'no' ? 0 : count,
      meal_preference: mealPreference && mealPreference.trim() ? mealPreference.trim() : null,
      dietary_notes: dietaryNotes && dietaryNotes.trim() ? dietaryNotes.trim() : null,
      message: message && message.trim() ? message.trim() : null,
      responded_at: new Date(),
    };

    let rsvp;
    if (existing) {
      await existing.update(values);
      rsvp = existing;
    } else {
      rsvp = await RsvpResponse.create(values);
    }
    res.status(201).json({ rsvp: serializeRsvp(rsvp, guest.name) });
  } catch (err) {
    console.error('Submit RSVP error:', err.message);
    res.status(500).json({ error: 'Could not save RSVP.' });
  }
});

router.delete('/responses/:rsvpId', async (req, res) => {
  try {
    const rsvp = await RsvpResponse.findOne({ where: { rsvp_id: req.params.rsvpId, couple_user_id: req.user.user_id } });
    if (!rsvp) return res.status(404).json({ error: 'RSVP not found.' });
    await rsvp.destroy();
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete RSVP error:', err.message);
    res.status(500).json({ error: 'Could not delete RSVP.' });
  }
});

router.patch('/responses/:rsvpId', async (req, res) => {
  try {
    const rsvp = await RsvpResponse.findOne({ where: { rsvp_id: req.params.rsvpId, couple_user_id: req.user.user_id } });
    if (!rsvp) return res.status(404).json({ error: 'RSVP not found.' });

    const { attending } = req.body;
    if (!['yes', 'no', 'maybe'].includes(attending)) {
      return res.status(400).json({ error: 'attending must be "yes", "no", or "maybe".' });
    }
    rsvp.attending = attending;
    if (attending === 'no') rsvp.guest_count = 0;
    rsvp.responded_at = new Date();
    await rsvp.save();
    const [serialized] = await serializeRsvps([rsvp]);
    res.json({ rsvp: serialized });
  } catch (err) {
    console.error('Update RSVP status error:', err.message);
    res.status(500).json({ error: 'Could not update RSVP.' });
  }
});

module.exports = router;

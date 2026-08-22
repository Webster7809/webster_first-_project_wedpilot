const crypto = require('crypto');
const express = require('express');
const rateLimit = require('express-rate-limit');
const { Op } = require('sequelize');
const Guest = require('../db/models/guest');
const Invitation = require('../db/models/invitation');
const RsvpResponse = require('../db/models/rsvpResponse');
const RsvpQuestion = require('../db/models/rsvpQuestion');
const RsvpAnswer = require('../db/models/rsvpAnswer');
const RsvpHistory = require('../db/models/rsvpHistory');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');
const { generateCardNumber } = require('../services/guestCardNumber');

const router = express.Router();
router.use(verifyJwt, requireCouple);

// Generous enough for a real door check-in rush, tight enough to slow down
// brute-forcing card numbers even from a compromised couple session — same
// pattern as authLimiter/passwordResetLimiter in routes/auth.js.
const checkinLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many check-in attempts. Please wait a few minutes and try again.' },
});

// ── Serialization ────────────────────────────────────────────────────────────────

// Flutter web now uses a path URL strategy (see usePathUrlStrategy() in
// lib/main.dart), so links are plain paths — no `#/` hash fragment. A hash
// fragment is silently dropped by some SMS/messaging apps' auto-linkifiers
// (they treat `#` as a hashtag boundary), which sent guests to the app's
// default route instead of their invitation.
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
    invite_url: g.invite_token ? `${PUBLIC_WEB_BASE_URL}/g/${g.invite_token}` : null,
    card_number: g.card_number,
    max_party_size: g.max_party_size,
    checked_in: g.checked_in,
    checked_in_at: g.checked_in_at,
  };
}

function generateInviteToken() {
  return crypto.randomBytes(8).toString('hex');
}

function serializeRsvp(r, guestName, answers = []) {
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
    answers,
  };
}

/// Batch-resolves each response's guest's current name, and (for the
/// dashboard's per-question tally) each response's custom-question answers
/// with their question text/type resolved alongside.
async function serializeRsvps(responses) {
  if (responses.length === 0) return [];
  const guestIds = [...new Set(responses.map((r) => r.guest_id))];
  const rsvpIds = responses.map((r) => r.rsvp_id);
  const [guests, allAnswers] = await Promise.all([
    Guest.findAll({ where: { guest_id: { [Op.in]: guestIds } } }),
    RsvpAnswer.findAll({ where: { rsvp_id: { [Op.in]: rsvpIds } } }),
  ]);
  const nameById = new Map(guests.map((g) => [g.guest_id, g.name]));

  const questionIds = [...new Set(allAnswers.map((a) => a.question_id))];
  const questions = questionIds.length
    ? await RsvpQuestion.findAll({ where: { question_id: { [Op.in]: questionIds } } })
    : [];
  const questionById = new Map(questions.map((q) => [q.question_id, q]));

  const answersByRsvpId = new Map();
  for (const a of allAnswers) {
    const question = questionById.get(a.question_id);
    if (!question) continue; // orphaned by a hard-deleted question; skip
    const list = answersByRsvpId.get(a.rsvp_id) ?? [];
    list.push({
      question_id: a.question_id,
      question_text: question.question_text,
      type: question.type,
      answer_text: a.answer_text,
      answer_json: a.answer_json,
    });
    answersByRsvpId.set(a.rsvp_id, list);
  }

  return responses.map((r) =>
    serializeRsvp(r, nameById.get(r.guest_id) ?? null, answersByRsvpId.get(r.rsvp_id) ?? []));
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

// null/undefined means "uncapped" and is always valid — only a stated value
// out of range is rejected.
function validateMaxPartySize(maxPartySize) {
  if (maxPartySize === undefined || maxPartySize === null || maxPartySize === '') return null;
  const n = Number(maxPartySize);
  if (!Number.isInteger(n) || n < 1 || n > 20) {
    return 'Max party size must be a whole number between 1 and 20.';
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
    const { name, email, phone, relation, invitationId, maxPartySize } = req.body;
    const error = validateGuestInput({ name, email, phone }) || validateMaxPartySize(maxPartySize);
    if (error) return res.status(400).json({ error });

    const duplicate = await Guest.findOne({
      where: { couple_user_id: req.user.user_id, name: { [Op.like]: name.trim() } },
    });
    if (duplicate) return res.status(409).json({ error: `A guest named "${name.trim()}" already exists.` });

    // A guest added by name is a known individual, not a walk-in off a
    // broadcast link — so they get their own locked personal link (see
    // POST /public/guest/:inviteToken/rsvp) the moment they exist, instead of
    // only once the couple remembers to tap "Share" on their card.
    let invite_token = null;
    let invite_invitation_id = null;
    if (invitationId) {
      const invitation = await Invitation.findOne({
        where: { invitation_id: invitationId, couple_user_id: req.user.user_id },
      });
      if (invitation) {
        invite_token = generateInviteToken();
        invite_invitation_id = invitationId;
      }
    }

    const guest = await Guest.create({
      couple_user_id: req.user.user_id,
      name: name.trim(),
      email: email && email.trim() ? email.trim() : null,
      phone: phone && phone.trim() ? phone.trim() : null,
      relation: relation && relation.trim() ? relation.trim() : null,
      is_invited: true,
      card_number: await generateCardNumber(),
      max_party_size: maxPartySize ? Number(maxPartySize) : null,
      invite_token,
      invite_invitation_id,
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

    const { name, email, phone, relation, maxPartySize } = req.body;
    const error = validateGuestInput({ name, email, phone }) || validateMaxPartySize(maxPartySize);
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
    guest.max_party_size = maxPartySize ? Number(maxPartySize) : null;
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

// ── Door check-in ──────────────────────────────────────────────────────────────
// Confirms the physical card a guest is holding actually belongs to someone
// on this couple's own list — the identity check a forwarded invite link
// can't provide by itself. Scoped to req.user.user_id like every other route
// here, so a card number only ever resolves within the couple checking it in,
// never across weddings.

router.post('/checkin', checkinLimiter, async (req, res) => {
  try {
    const { cardNumber } = req.body;
    if (!cardNumber || !String(cardNumber).trim()) {
      return res.status(400).json({ error: 'Card number is required.' });
    }

    const guest = await Guest.findOne({
      where: { couple_user_id: req.user.user_id, card_number: String(cardNumber).trim() },
    });
    if (!guest) {
      return res.status(404).json({ error: 'No guest found with that card number.' });
    }
    if (guest.checked_in) {
      return res.status(409).json({
        error: `${guest.name} was already checked in at ${new Date(guest.checked_in_at).toLocaleString()}.`,
        guest: serializeGuest(guest),
      });
    }

    guest.checked_in = true;
    guest.checked_in_at = new Date();
    await guest.save();
    res.json({ guest: serializeGuest(guest) });
  } catch (err) {
    console.error('Guest check-in error:', err.message);
    res.status(500).json({ error: 'Could not check in this guest.' });
  }
});

// Corrects a mistaken check-in (wrong card typed, duplicate scan) — from the
// guest list rather than the card number, since the couple is looking at the
// guest's name at that point, not their card.
router.patch('/:id/toggle-checkin', async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { guest_id: req.params.id, couple_user_id: req.user.user_id } });
    if (!guest) return res.status(404).json({ error: 'Guest not found.' });

    guest.checked_in = !guest.checked_in;
    guest.checked_in_at = guest.checked_in ? new Date() : null;
    await guest.save();
    res.json({ guest: serializeGuest(guest) });
  } catch (err) {
    console.error('Toggle check-in error:', err.message);
    res.status(500).json({ error: 'Could not update guest.' });
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
    if (guest.max_party_size && count > guest.max_party_size) {
      return res.status(400).json({
        error: `This invitation is for a maximum of ${guest.max_party_size} people.`,
      });
    }

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

    // Captured before .update() below, which mutates `existing` in place —
    // reading these fields off it afterward would silently record "no
    // change" (previous == new) on every edit.
    const previousStatus = existing?.attending ?? null;
    const previousGuestCount = existing?.guest_count ?? null;

    let rsvp;
    if (existing) {
      await existing.update(values);
      rsvp = existing;
    } else {
      rsvp = await RsvpResponse.create(values);
    }

    // Couple-initiated (manual guest-list entry), so it's logged — unlike a
    // guest editing their own RSVP through their link, this is staff
    // intervention worth a paper trail.
    await RsvpHistory.create({
      rsvp_id: rsvp.rsvp_id,
      changed_by_user_id: req.user.user_id,
      previous_status: previousStatus,
      new_status: values.attending,
      previous_guest_count: previousGuestCount,
      new_guest_count: values.guest_count,
      changed_at: new Date(),
    });

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
    const previousStatus = rsvp.attending;
    const previousGuestCount = rsvp.guest_count;
    rsvp.attending = attending;
    if (attending === 'no') rsvp.guest_count = 0;
    rsvp.responded_at = new Date();
    await rsvp.save();

    await RsvpHistory.create({
      rsvp_id: rsvp.rsvp_id,
      changed_by_user_id: req.user.user_id,
      previous_status: previousStatus,
      new_status: rsvp.attending,
      previous_guest_count: previousGuestCount,
      new_guest_count: rsvp.guest_count,
      changed_at: new Date(),
    });

    const [serialized] = await serializeRsvps([rsvp]);
    res.json({ rsvp: serialized });
  } catch (err) {
    console.error('Update RSVP status error:', err.message);
    res.status(500).json({ error: 'Could not update RSVP.' });
  }
});

// Couple-initiated edits only (see RsvpHistory.create() calls above) — a
// guest revising their own RSVP through their link is never logged here.
router.get('/responses/:rsvpId/history', async (req, res) => {
  try {
    const rsvp = await RsvpResponse.findOne({
      where: { rsvp_id: req.params.rsvpId, couple_user_id: req.user.user_id },
    });
    if (!rsvp) return res.status(404).json({ error: 'RSVP not found.' });

    const rows = await RsvpHistory.findAll({
      where: { rsvp_id: rsvp.rsvp_id },
      order: [['changed_at', 'DESC']],
    });
    res.json({
      history: rows.map((h) => ({
        history_id: h.history_id,
        previous_status: h.previous_status,
        new_status: h.new_status,
        previous_guest_count: h.previous_guest_count,
        new_guest_count: h.new_guest_count,
        changed_at: h.changed_at,
      })),
    });
  } catch (err) {
    console.error('List RSVP history error:', err.message);
    res.status(500).json({ error: 'Could not load RSVP history.' });
  }
});

module.exports = router;

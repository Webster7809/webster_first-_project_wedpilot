const crypto = require('crypto');
const express = require('express');
const rateLimit = require('express-rate-limit');
const { Op } = require('sequelize');
const Invitation = require('../db/models/invitation');
const Guest = require('../db/models/guest');
const MealOption = require('../db/models/mealOption');
const RsvpResponse = require('../db/models/rsvpResponse');
const RsvpQuestion = require('../db/models/rsvpQuestion');
const RsvpAnswer = require('../db/models/rsvpAnswer');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');
const { makeUploader, relativeUploadUrl } = require('../middleware/upload');
const { generateCardNumber } = require('../services/guestCardNumber');

const router = express.Router();
const photoUploader = makeUploader('invitations', { allowedMimePrefixes: ['image/'], maxSizeMb: 15 });

// Unauthenticated RSVP submission is the one write path a stranger can hit
// directly — same pattern as authLimiter in routes/auth.js. Generous enough
// for a guest fumbling the form a few times, tight enough to slow down
// scripted abuse of either link type.
const publicRsvpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Please wait a few minutes and try again.' },
});

// ── Serialization ────────────────────────────────────────────────────────────────

// Flutter web now uses a path URL strategy (see usePathUrlStrategy() in
// lib/main.dart), so links are plain paths — no `#/` hash fragment. A hash
// fragment is silently dropped by some SMS/messaging apps' auto-linkifiers
// (they treat `#` as a hashtag boundary), which sent guests to the app's
// default route instead of their invitation.
const PUBLIC_WEB_BASE_URL = process.env.PUBLIC_WEB_BASE_URL || 'http://localhost:8080';

function serializeInvitation(inv) {
  return {
    invitation_id: inv.invitation_id,
    couple_id: inv.couple_user_id,
    template_id: inv.template_id,
    title: inv.title,
    custom_data: inv.custom_data,
    share_token: inv.share_token,
    share_url: inv.status === 'published' ? `${PUBLIC_WEB_BASE_URL}/i/${inv.share_token}` : null,
    thumbnail_url: null,
    status: inv.status,
    view_count: inv.view_count,
    created_at: inv.created_at,
  };
}

function generateShareToken() {
  return crypto.randomBytes(8).toString('hex');
}

// The couple's optional total headcount cap for a card, e.g. "this
// invitation is for 120 people" — stored alongside every other
// editor-configurable field on custom_data rather than a dedicated column
// (see invitations.js's generic PATCH /:id merge). Null/invalid means
// uncapped, same convention as Guest.max_party_size.
function readMaxGuests(invitation) {
  const raw = invitation.custom_data?.maxGuests;
  const n = Number(raw);
  return Number.isInteger(n) && n > 0 ? n : null;
}

// Sums guest_count across every RSVP tied to this invitation — personal
// links and the shared link alike — for everyone who isn't a firm "no".
// This is what a couple's stated cap is measured against: the whole card's
// confirmed+tentative headcount, not just the shared-link portion of it.
async function confirmedGuestCount(invitationId) {
  const total = await RsvpResponse.sum('guest_count', {
    where: { invitation_id: invitationId, attending: { [Op.ne]: 'no' } },
  });
  return total || 0;
}

// Guest names are matched with LIKE (for MySQL's case-insensitive default
// collation), so `%` and `_` in submitted text would be wildcards rather than
// characters. Now that a name match is what gates the broadcast link, typing
// "%" must not resolve to "the first guest on this couple's list" and burn
// their single-use slot.
function escapeLike(value) {
  return value.replace(/[\\%_]/g, (char) => `\\${char}`);
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

router.delete('/:id', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { invitation_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    // Clean up everything hanging off this invitation: its RSVPs, and any
    // per-guest invite links pointing at it (the guests themselves stay).
    await RsvpResponse.destroy({ where: { invitation_id: invitation.invitation_id } });
    await Guest.update(
      { invite_invitation_id: null, invite_token: null },
      { where: { invite_invitation_id: invitation.invitation_id } },
    );
    await invitation.destroy();
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete invitation error:', err.message);
    res.status(500).json({ error: 'Could not delete invitation.' });
  }
});

// ── Meal options (couple-owned) ────────────────────────────────────────────────────
// Configurable per invitation, rendered as a choice list on the public RSVP
// form instead of free text (see the public GET routes below, which embed
// the current list). RsvpResponse.meal_preference has no FK back here —
// editing/removing an option later must never touch an existing answer.

function serializeMealOption(o) {
  return { option_id: o.option_id, invitation_id: o.invitation_id, label: o.label, sort_order: o.sort_order };
}

async function findOwnedInvitation(invitationId, coupleUserId) {
  return Invitation.findOne({ where: { invitation_id: invitationId, couple_user_id: coupleUserId } });
}

router.get('/:id/meal-options', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await findOwnedInvitation(req.params.id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const options = await MealOption.findAll({
      where: { invitation_id: invitation.invitation_id },
      order: [['sort_order', 'ASC']],
    });
    res.json({ meal_options: options.map(serializeMealOption) });
  } catch (err) {
    console.error('List meal options error:', err.message);
    res.status(500).json({ error: 'Could not load meal options.' });
  }
});

router.post('/:id/meal-options', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await findOwnedInvitation(req.params.id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const { label } = req.body;
    if (!label || !label.trim()) return res.status(400).json({ error: 'A label is required.' });

    const count = await MealOption.count({ where: { invitation_id: invitation.invitation_id } });
    const option = await MealOption.create({
      invitation_id: invitation.invitation_id,
      label: label.trim(),
      sort_order: count,
    });
    res.status(201).json({ meal_option: serializeMealOption(option) });
  } catch (err) {
    console.error('Add meal option error:', err.message);
    res.status(500).json({ error: 'Could not add meal option.' });
  }
});

router.patch('/meal-options/:optionId', verifyJwt, requireCouple, async (req, res) => {
  try {
    const option = await MealOption.findOne({ where: { option_id: req.params.optionId } });
    if (!option) return res.status(404).json({ error: 'Meal option not found.' });
    const invitation = await findOwnedInvitation(option.invitation_id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'Meal option not found.' });

    const { label } = req.body;
    if (!label || !label.trim()) return res.status(400).json({ error: 'A label is required.' });
    option.label = label.trim();
    await option.save();
    res.json({ meal_option: serializeMealOption(option) });
  } catch (err) {
    console.error('Edit meal option error:', err.message);
    res.status(500).json({ error: 'Could not update meal option.' });
  }
});

router.delete('/meal-options/:optionId', verifyJwt, requireCouple, async (req, res) => {
  try {
    const option = await MealOption.findOne({ where: { option_id: req.params.optionId } });
    if (!option) return res.status(404).json({ error: 'Meal option not found.' });
    const invitation = await findOwnedInvitation(option.invitation_id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'Meal option not found.' });

    await option.destroy();
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete meal option error:', err.message);
    res.status(500).json({ error: 'Could not delete meal option.' });
  }
});

// ── Custom RSVP questions (couple-owned) ───────────────────────────────────────────
// Answered alongside the RSVP itself in the public POST routes below.
// `options` only applies to single_choice/multi_choice; every other type
// stores null there.

const QUESTION_TYPES = ['yes_no', 'single_choice', 'multi_choice', 'short_text', 'long_text', 'number'];
const CHOICE_TYPES = ['single_choice', 'multi_choice'];

function serializeQuestion(q) {
  return {
    question_id: q.question_id,
    invitation_id: q.invitation_id,
    question_text: q.question_text,
    type: q.type,
    options: q.options,
    is_required: q.is_required,
    is_enabled: q.is_enabled,
    sort_order: q.sort_order,
  };
}

function validateQuestionInput({ questionText, type, options }) {
  if (!questionText || !questionText.trim()) return 'Question text is required.';
  if (!QUESTION_TYPES.includes(type)) return `type must be one of: ${QUESTION_TYPES.join(', ')}.`;
  if (CHOICE_TYPES.includes(type)) {
    if (!Array.isArray(options) || options.filter((o) => typeof o === 'string' && o.trim()).length < 2) {
      return 'Choice questions need at least 2 options.';
    }
  }
  return null;
}

router.get('/:id/rsvp-questions', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await findOwnedInvitation(req.params.id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const questions = await RsvpQuestion.findAll({
      where: { invitation_id: invitation.invitation_id },
      order: [['sort_order', 'ASC']],
    });
    res.json({ rsvp_questions: questions.map(serializeQuestion) });
  } catch (err) {
    console.error('List RSVP questions error:', err.message);
    res.status(500).json({ error: 'Could not load RSVP questions.' });
  }
});

router.post('/:id/rsvp-questions', verifyJwt, requireCouple, async (req, res) => {
  try {
    const invitation = await findOwnedInvitation(req.params.id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const { questionText, type, options, isRequired } = req.body;
    const error = validateQuestionInput({ questionText, type, options });
    if (error) return res.status(400).json({ error });

    const count = await RsvpQuestion.count({ where: { invitation_id: invitation.invitation_id } });
    const question = await RsvpQuestion.create({
      invitation_id: invitation.invitation_id,
      question_text: questionText.trim(),
      type,
      options: CHOICE_TYPES.includes(type)
        ? options.filter((o) => typeof o === 'string' && o.trim()).map((o) => o.trim())
        : null,
      is_required: !!isRequired,
      sort_order: count,
    });
    res.status(201).json({ rsvp_question: serializeQuestion(question) });
  } catch (err) {
    console.error('Add RSVP question error:', err.message);
    res.status(500).json({ error: 'Could not add RSVP question.' });
  }
});

router.patch('/rsvp-questions/:questionId', verifyJwt, requireCouple, async (req, res) => {
  try {
    const question = await RsvpQuestion.findOne({ where: { question_id: req.params.questionId } });
    if (!question) return res.status(404).json({ error: 'RSVP question not found.' });
    const invitation = await findOwnedInvitation(question.invitation_id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'RSVP question not found.' });

    // Toggling enabled state doesn't require re-validating the rest of the
    // question — a couple disabling a question they can no longer fully
    // edit (it already has answers) must still be possible.
    if (typeof req.body.isEnabled === 'boolean' && Object.keys(req.body).length === 1) {
      question.is_enabled = req.body.isEnabled;
      await question.save();
      return res.json({ rsvp_question: serializeQuestion(question) });
    }

    const { questionText, type, options, isRequired, isEnabled } = req.body;
    const error = validateQuestionInput({ questionText, type, options });
    if (error) return res.status(400).json({ error });

    question.question_text = questionText.trim();
    question.type = type;
    question.options = CHOICE_TYPES.includes(type)
      ? options.filter((o) => typeof o === 'string' && o.trim()).map((o) => o.trim())
      : null;
    question.is_required = !!isRequired;
    if (typeof isEnabled === 'boolean') question.is_enabled = isEnabled;
    await question.save();
    res.json({ rsvp_question: serializeQuestion(question) });
  } catch (err) {
    console.error('Edit RSVP question error:', err.message);
    res.status(500).json({ error: 'Could not update RSVP question.' });
  }
});

router.delete('/rsvp-questions/:questionId', verifyJwt, requireCouple, async (req, res) => {
  try {
    const question = await RsvpQuestion.findOne({ where: { question_id: req.params.questionId } });
    if (!question) return res.status(404).json({ error: 'RSVP question not found.' });
    const invitation = await findOwnedInvitation(question.invitation_id, req.user.user_id);
    if (!invitation) return res.status(404).json({ error: 'RSVP question not found.' });

    const answerCount = await RsvpAnswer.count({ where: { question_id: question.question_id } });
    if (answerCount > 0) {
      return res.status(409).json({
        error: 'Guests have already answered this question — disable it instead of deleting it.',
      });
    }

    await question.destroy();
    res.json({ deleted: true });
  } catch (err) {
    console.error('Delete RSVP question error:', err.message);
    res.status(500).json({ error: 'Could not delete RSVP question.' });
  }
});

// Validates submitted answers against this invitation's enabled questions and
// returns { error } (400, missing a required answer) or { rows } ready for
// RsvpAnswer.bulkCreate. Skips required-question enforcement when declining —
// an allergy/transport question shouldn't block a "no."
function buildAnswerRows(questions, submittedAnswers, rsvpId, attending) {
  const byId = new Map(questions.map((q) => [q.question_id, q]));
  const answerById = new Map(
    (Array.isArray(submittedAnswers) ? submittedAnswers : [])
      .filter((a) => a && typeof a.questionId === 'string')
      .map((a) => [a.questionId, a]),
  );

  const rows = [];
  for (const question of questions) {
    const answer = answerById.get(question.question_id);
    const isMulti = question.type === 'multi_choice';
    const hasValue = isMulti
      ? Array.isArray(answer?.answerJson) && answer.answerJson.length > 0
      : typeof answer?.answerText === 'string' && answer.answerText.trim() !== '';

    if (question.is_required && attending !== 'no' && !hasValue) {
      return { error: `Please answer: ${question.question_text}` };
    }
    if (!hasValue) continue;

    if (isMulti) {
      const selected = answer.answerJson.filter((v) => typeof v === 'string' && v.trim());
      rows.push({ rsvp_id: rsvpId, question_id: question.question_id, answer_text: null, answer_json: selected });
    } else {
      rows.push({ rsvp_id: rsvpId, question_id: question.question_id, answer_text: String(answer.answerText).trim(), answer_json: null });
    }
  }
  return { rows };
}

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

    const mealOptions = await MealOption.findAll({
      where: { invitation_id: invitation.invitation_id },
      order: [['sort_order', 'ASC']],
    });
    const questions = await RsvpQuestion.findAll({
      where: { invitation_id: invitation.invitation_id, is_enabled: true },
      order: [['sort_order', 'ASC']],
    });
    const maxGuests = readMaxGuests(invitation);

    res.json({
      invitation: serializeInvitation(invitation),
      meal_options: mealOptions.map(serializeMealOption),
      rsvp_questions: questions.map(serializeQuestion),
      max_guests: maxGuests,
      // Only computed when a cap is actually set — this is a second query
      // per view, worth skipping for the (common) uncapped case.
      confirmed_guest_count: maxGuests != null ? await confirmedGuestCount(invitation.invitation_id) : null,
    });
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
    const mealOptions = await MealOption.findAll({
      where: { invitation_id: invitation.invitation_id },
      order: [['sort_order', 'ASC']],
    });
    const questions = await RsvpQuestion.findAll({
      where: { invitation_id: invitation.invitation_id, is_enabled: true },
      order: [['sort_order', 'ASC']],
    });
    const existingAnswers = existingRsvp
      ? await RsvpAnswer.findAll({ where: { rsvp_id: existingRsvp.rsvp_id } })
      : [];

    res.json({
      invitation: serializeInvitation(invitation),
      guest: { guest_id: guest.guest_id, name: guest.name, max_party_size: guest.max_party_size },
      already_responded: !!existingRsvp,
      existing_response: existingRsvp
        ? {
            attending: existingRsvp.attending,
            guest_count: existingRsvp.guest_count,
            meal_preference: existingRsvp.meal_preference,
            dietary_notes: existingRsvp.dietary_notes,
            message: existingRsvp.message,
            answers: existingAnswers.map((a) => ({
              question_id: a.question_id,
              answer_text: a.answer_text,
              answer_json: a.answer_json,
            })),
          }
        : null,
      meal_options: mealOptions.map(serializeMealOption),
      rsvp_questions: questions.map(serializeQuestion),
    });
  } catch (err) {
    console.error('Public guest invitation lookup error:', err.message);
    res.status(500).json({ error: 'Could not load invitation.' });
  }
});

router.post('/public/guest/:inviteToken/rsvp', publicRsvpLimiter, async (req, res) => {
  try {
    const guest = await Guest.findOne({ where: { invite_token: req.params.inviteToken } });
    if (!guest || !guest.invite_invitation_id) {
      return res.status(404).json({ error: 'Invitation not found.' });
    }

    const invitation = await Invitation.findOne({
      where: { invitation_id: guest.invite_invitation_id, status: 'published' },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    // Single-use: a personal link is scoped to one named guest, and once
    // they've answered once the link is done — reopening or resubmitting it
    // (by that guest again, or by anyone it got forwarded to) can no longer
    // change the answer. Viewing (the GET route above) never locks anything;
    // only a successful submission does.
    const alreadyResponded = await RsvpResponse.findOne({ where: { guest_id: guest.guest_id } });
    if (alreadyResponded) {
      return res.status(409).json({
        error: 'This invitation has already been used to RSVP and cannot be changed.',
      });
    }

    const { attending, mealPreference, dietaryNotes, message, answers } = req.body;
    if (!['yes', 'no', 'maybe'].includes(attending)) {
      return res.status(400).json({ error: 'attending must be "yes", "no", or "maybe".' });
    }
    // How many people this invitation covers is set by the couple
    // (guest.max_party_size) — never a number the guest submitting gets to
    // choose. See guests.js POST /:id/rsvp for where the couple sets it.
    const count = guest.max_party_size || 1;

    const questions = await RsvpQuestion.findAll({
      where: { invitation_id: invitation.invitation_id, is_enabled: true },
    });
    const built = buildAnswerRows(questions, answers, null, attending);
    if (built.error) return res.status(400).json({ error: built.error });

    const values = {
      couple_user_id: invitation.couple_user_id,
      invitation_id: invitation.invitation_id,
      guest_id: guest.guest_id,
      attending,
      guest_count: attending === 'no' ? 0 : count,
      meal_preference: mealPreference && mealPreference.trim() ? mealPreference.trim() : null,
      dietary_notes: dietaryNotes && dietaryNotes.trim() ? dietaryNotes.trim() : null,
      message: message && message.trim() ? message.trim() : null,
      responded_at: new Date(),
    };

    let rsvp;
    try {
      rsvp = await RsvpResponse.create(values);
    } catch (err) {
      // Closes the race between the check above and this insert — see
      // migration 017's unique index on guest_id. Two near-simultaneous
      // submissions through the same link now can't both succeed.
      if (err.name === 'SequelizeUniqueConstraintError') {
        return res.status(409).json({
          error: 'This invitation has already been used to RSVP and cannot be changed.',
        });
      }
      throw err;
    }

    if (built.rows.length > 0) {
      await RsvpAnswer.bulkCreate(built.rows.map((r) => ({ ...r, rsvp_id: rsvp.rsvp_id })));
    }

    res.status(201).json({ submitted: true });
  } catch (err) {
    console.error('Public guest RSVP submit error:', err.message);
    res.status(500).json({ error: 'Could not submit RSVP.' });
  }
});

router.post('/public/:shareToken/rsvp', publicRsvpLimiter, async (req, res) => {
  try {
    const invitation = await Invitation.findOne({
      where: { share_token: req.params.shareToken, status: 'published' },
    });
    if (!invitation) return res.status(404).json({ error: 'Invitation not found.' });

    const { name, email, attending, mealPreference, dietaryNotes, message, answers } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ error: 'Name is required.' });
    if (!['yes', 'no', 'maybe'].includes(attending)) {
      return res.status(400).json({ error: 'attending must be "yes", "no", or "maybe".' });
    }

    // The broadcast link is open by design — anyone it reaches can type their
    // own name. Look for an existing guest on the couple's list
    // (case-insensitive) so someone pre-added still gets tracked as one
    // person; an unmatched name means a new ad-hoc guest, but creating that
    // row is deferred past every check below so a rejected attempt (already
    // responded, over the couple's cap) never leaves a walk-in stub with no
    // RSVP behind on the guest list.
    const existingGuest = await Guest.findOne({
      where: { couple_user_id: invitation.couple_user_id, name: { [Op.like]: escapeLike(name.trim()) } },
    });

    // Single-use per name: once this guest has answered, reopening the shared
    // link and retyping their name can't change or re-spend their invitation
    // — the mechanism that stops a forwarded link from letting the same
    // person (or anyone reusing their name) inflate the headcount by
    // resubmitting. A brand-new name can't have answered yet, so this only
    // applies once a match is found.
    if (existingGuest) {
      const alreadyResponded = await RsvpResponse.findOne({ where: { guest_id: existingGuest.guest_id } });
      if (alreadyResponded) {
        return res.status(409).json({
          error: 'This name has already been used to RSVP and cannot be changed.',
        });
      }
    }

    // How many people this invitation covers is set by the couple
    // (guest.max_party_size) — never a number the guest submitting gets to
    // choose. An ad-hoc walk-in was never given one, so they default to 1,
    // same as any other un-configured invitation.
    const count = existingGuest?.max_party_size || 1;

    // The couple's total headcount cap for the card, if they set one. Only
    // attending yes/maybe adds to it — declining never did (guest_count is
    // zeroed below either way), so a "no" can never be blocked by this.
    if (attending !== 'no') {
      const maxGuests = readMaxGuests(invitation);
      if (maxGuests != null) {
        const soFar = await confirmedGuestCount(invitation.invitation_id);
        if (soFar + count > maxGuests) {
          return res.status(409).json({
            error: 'This invitation has reached its guest limit and can no longer accept RSVPs.',
          });
        }
      }
    }

    const guest = existingGuest || await Guest.create({
      couple_user_id: invitation.couple_user_id,
      name: name.trim(),
      email: email && email.trim() ? email.trim() : null,
      is_invited: true,
      card_number: await generateCardNumber(),
      max_party_size: 1,
    });

    const questions = await RsvpQuestion.findAll({
      where: { invitation_id: invitation.invitation_id, is_enabled: true },
    });
    const built = buildAnswerRows(questions, answers, null, attending);
    if (built.error) return res.status(400).json({ error: built.error });

    const values = {
      couple_user_id: invitation.couple_user_id,
      invitation_id: invitation.invitation_id,
      guest_id: guest.guest_id,
      attending,
      guest_count: attending === 'no' ? 0 : count,
      meal_preference: mealPreference && mealPreference.trim() ? mealPreference.trim() : null,
      dietary_notes: dietaryNotes && dietaryNotes.trim() ? dietaryNotes.trim() : null,
      message: message && message.trim() ? message.trim() : null,
      responded_at: new Date(),
    };

    let rsvp;
    try {
      rsvp = await RsvpResponse.create(values);
    } catch (err) {
      // Same race the personal link closes — see migration 017's unique index
      // on guest_id.
      if (err.name === 'SequelizeUniqueConstraintError') {
        return res.status(409).json({
          error: 'This name has already been used to RSVP and cannot be changed.',
        });
      }
      throw err;
    }

    if (built.rows.length > 0) {
      await RsvpAnswer.bulkCreate(built.rows.map((r) => ({ ...r, rsvp_id: rsvp.rsvp_id })));
    }

    // Only ever fills a blank — a contact detail the couple already recorded
    // is theirs, and an unauthenticated form must not be able to overwrite it.
    if (!guest.email && email && email.trim()) {
      guest.email = email.trim();
      await guest.save();
    }

    res.status(201).json({ submitted: true });
  } catch (err) {
    console.error('Public RSVP submit error:', err.message);
    res.status(500).json({ error: 'Could not submit RSVP.' });
  }
});

module.exports = router;

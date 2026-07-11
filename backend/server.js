require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const sequelize = require('./db/sequelize');
require('./db/models/user');
require('./db/models/coupleProfile');
require('./db/models/task');
require('./db/models/vendor');
require('./db/models/vendorService');
require('./db/models/vendorMedia');
require('./db/models/vendorFeedback');
require('./db/models/vendorStats');
require('./db/models/inquiry');
require('./db/models/savedVendor');
require('./db/models/budget');
require('./db/models/budgetCategory');
require('./db/models/budgetCustomItem');
require('./db/models/expense');
require('./db/models/guest');
require('./db/models/invitation');
require('./db/models/rsvpResponse');
require('./db/models/conversation');
require('./db/models/message');
require('./db/models/notification');
require('./db/models/vendorMatch');
const authRoutes = require('./routes/auth');
const coupleProfileRoutes = require('./routes/coupleProfile');
const taskRoutes = require('./routes/tasks');
const vendorRoutes = require('./routes/vendors');
const wishlistRoutes = require('./routes/wishlist');
const budgetRoutes = require('./routes/budget');
const adminRoutes = require('./routes/admin');
const guestRoutes = require('./routes/guests');
const invitationRoutes = require('./routes/invitations');
const messagingRoutes = require('./routes/messaging');
const notificationRoutes = require('./routes/notifications');

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth', authRoutes);
app.use('/api/couple', coupleProfileRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/vendors', vendorRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/budget', budgetRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/guests', guestRoutes);
app.use('/api/invitations', invitationRoutes);
app.use('/api/messages', messagingRoutes);
app.use('/api/notifications', notificationRoutes);

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const GEMINI_MODEL = 'gemini-2.5-flash';

// Persona shared by every planning/matching call — this is what makes the
// output read like expert judgement instead of generic AI filler.
const PLANNER_PERSONA = `You are Aisha Mwansa, an award-winning, internationally certified wedding
planner with 20+ years designing weddings across Zambia and the wider SADC region. You have
planned weddings featured in Brides Africa and mentored dozens of junior planners. You are
renowned for razor-sharp budget discipline, deep vendor-market knowledge, and reasoning that
cites concrete factors (guest-count scaling, seasonal/location cost swings, industry-standard
allocation benchmarks, style-fit) rather than generic platitudes. Every recommendation you give
must sound like it came from someone who has personally run hundreds of weddings, not a
template.`;

const geminiModel = genAI.getGenerativeModel({
  model: GEMINI_MODEL,
  systemInstruction: PLANNER_PERSONA,
  generationConfig: {
    responseMimeType: 'application/json',
    // Lets Gemini 2.5 Flash actually reason before answering instead of
    // pattern-matching straight to an output — budget is dynamic (-1) so it
    // spends more thinking on harder requests (more categories, edge-case
    // budgets) and less on simple ones.
    thinkingConfig: { thinkingBudget: -1 },
  },
});

// Both endpoints ask for JSON in the prompt itself and extract the first
// {...} span from the response text.
async function askGemini(prompt) {
  const result = await geminiModel.generateContent(prompt);
  const text = result.response.text();
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  return JSON.parse(text.substring(start, end + 1));
}

// ── POST /api/wedding-plan ────────────────────────────────────────────────────
app.post('/api/wedding-plan', async (req, res) => {
  const {
    totalBudget = 0,
    currency = 'ZMW',
    weddingType = 'White wedding',
    weddingClass = 'Flexible',
    guestCount = 0,
    location = 'Zambia',
    weddingDate,
    styles = [],
    categories = [],
    topVendorNames = {},
  } = req.body;

  const dateStr = weddingDate ? new Date(weddingDate).toLocaleDateString('en-GB') : 'Not set yet';
  const styleStr = styles.length ? styles.join(', ') : 'Not specified';
  const categoriesStr = categories.join(', ');
  const vendorLines = Object.entries(topVendorNames)
    .map(([cat, name]) => `  - ${cat}: "${name}"`)
    .join('\n') || '  (vendors not yet matched)';

  const prompt = `
A couple has come to you for a full wedding plan:
- Total budget: ${currency} ${Number(totalBudget).toFixed(0)}
- Wedding type: ${weddingType}
- Wedding class: ${weddingClass}
- Guest count: ${guestCount} guests
- Location: ${location}
- Wedding date: ${dateStr}
- Style preferences: ${styleStr}
- Vendor categories needed: ${categoriesStr}
- Top AI-matched vendor per category:
${vendorLines}

Think it through like you would in a real client consultation: weigh how guest count scales
per-head costs (catering, venue capacity), how the wedding class shifts spend toward premium
categories, how location affects vendor pricing and availability, and where this couple's
budget is tight or has room to flex. Then commit to a specific plan.

Respond ONLY with valid JSON:
{
  "planSummary": "A warm, confident 2-3 sentence personalised summary written like a planner opening a client consultation. Mention location, budget and date if set. Be specific to their choices, not generic.",
  "budgetAdvice": { "CategoryName": percentage_number },
  "budgetReasoning": { "CategoryName": "2-3 sentences of real planner reasoning for this exact percentage — reference guest-count math, industry-standard allocation ranges for this wedding class, or location cost factors. No filler." },
  "vendorReasonings": { "CategoryName": "1-2 sentences of specific, expert reasoning for why this vendor is the right fit for this couple." }
}

Rules:
- budgetAdvice must cover every category in [${categoriesStr}] and sum to exactly 100.
- Use plain numbers for percentages (e.g. 30, not "30%").
- budgetReasoning must cover every category in [${categoriesStr}] and justify that category's specific percentage — explain why it's higher or lower than an even split in concrete terms.
- vendorReasonings must cover every category that has a top vendor listed.
- Confident, expert, professional tone suited to a Zambian wedding market. Never hedge or say "it depends" — give a definitive recommendation.
- Never invent facts not given above — no couple names (none were provided), no vendor details beyond what's listed, no fabricated menu items or prices. Ground every claim only in the data given.
`;

  try {
    const json = await askGemini(prompt);
    res.json(json);
  } catch (err) {
    console.error('Gemini error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/vendor-match ────────────────────────────────────────────────────
app.post('/api/vendor-match', async (req, res) => {
  const {
    budgetClass = 'flexible', location = null, styles = [], categories = {}, categoryBudgets = {},
    specialRequests = null,
  } = req.body;

  const trimmedRequest = typeof specialRequests === 'string' ? specialRequests.trim() : '';

  const prompt = `
You're vetting vendors for a client. Couple context:
- Budget class: ${budgetClass}
- Location: ${location ?? 'Not specified'}
- Style preferences: ${styles.length ? styles.join(', ') : 'Not specified'}
- Allocated budget per category (their money, in local currency; a category absent here has no known cap):
${JSON.stringify(categoryBudgets, null, 2)}
- Free-text note the couple typed in an "anything else we should know?" box: ${trimmedRequest ? `"${trimmedRequest}"` : 'Not provided'}

${trimmedRequest ? `Before using that note, judge it for yourself: is it actually a real, wedding-relevant
preference or requirement (e.g. a dietary need, a setting/venue preference, an accessibility need, a
cultural/religious requirement, a style detail)? If it's gibberish, spam, off-topic, or otherwise not a
genuine wedding-planning instruction, reject it outright — do not reference it anywhere in your reasoning
and do not let it influence any pick. If it is genuine, then for each category below decide independently
whether that specific note actually applies to that category's vendors (e.g. "need halal catering" applies
to Catering, not to DJ & MC; "prefer garden settings" applies to Venue and maybe Decor & flowers, not to
Photography). Only where it genuinely applies: let it inform which candidate you pick for that category
(prefer a candidate whose profile/style tags/description are consistent with the request when candidates
are otherwise close), and add a 5th reasoning step for that category only (see format below). Never claim
the couple asked for something they didn't, and never bend a category's pick toward an irrelevant note.` : ''}

For each category below, you are given a pre-filtered candidate list. Each candidate already
passed eligibility rules and has three precomputed 0-1 signal scores: reputationScore (rating/
reviews/track record), locationScore (proximity to the couple — this is HIGH PRIORITY: treat it as
at least as important as reputation or price, and strongly prefer a nearby candidate over a
similarly-qualified one further away), valueScore (price fit for their budget class). Treat these
scores as inputs, not the final word — weigh them against style tag overlap with the couple's
preferences and each vendor's profile the way a seasoned planner would weigh a shortlist against a
client's brief, including trade-offs (e.g. a slightly lower-rated vendor whose style is a much
better fit). Only pick a candidate with a low locationScore as your primary recommendation when no
comparable nearby candidate exists in that category. Then commit to the single best vendor per
category.

Each candidate also has an isBookedOnWeddingDate flag: true means that vendor already has a
confirmed booking on the couple's wedding date (they blocked that date on their calendar) and is
very likely unavailable. Do not silently ignore this — strongly prefer an available (false)
candidate of comparable quality over a booked one. Only recommend a booked candidate if there is
no comparable available alternative in that category.

Each candidate carries priceMin/priceMax (the vendor's actual price range). For any category that
has an entry in the allocated-budget map above, you must search for and prefer a candidate whose
priceMin does not exceed that category's allocated amount — never recommend a vendor priced beyond
the couple's entered budget for that category if a candidate that fits exists. If every candidate in
that category is priced beyond the allocated amount (their money is simply too low for what's
available), you must still pick the closest/cheapest candidate rather than returning nothing.

CANDIDATE_VENDORS — the only real, verified vendors you may recommend or discuss, grouped by
category (JSON):
${JSON.stringify(categories, null, 2)}

You may only recommend a vendor whose vendorId appears in CANDIDATE_VENDORS for that exact
category. Every vendorId, businessName, price, rating, review count, style tag, and availability
flag you reference must be copied exactly, character-for-character, from this data — never invent,
alter, round, guess, or "helpfully" improve any of these values, and never reference a vendor that
isn't in this list. If you are ever unsure whether a value came from CANDIDATE_VENDORS, do not
state it.

Instead of one run-on explanation, break your justification for each pick into named, ordered steps
(like a planner walking through their checklist one line at a time). Always include these four:
1. "Budget fit" — state whether the price fits the couple's allocated budget for this category. If
   it doesn't fit (or no budget was given), say so plainly and, if it doesn't fit, offer one simple,
   concrete way to still move forward (e.g. negotiate a smaller/custom package, trim scope or guest
   count for this category, or shift budget over from a lower-priority category) — keep it
   encouraging and practical, not just a warning.
2. "Availability" — state whether isBookedOnWeddingDate is true or false for the picked vendor. If
   true, say plainly that they already appear booked on the couple's date and that the couple should
   confirm availability before committing, or consider a backup.
3. "Style match" — 2 short sentences. First, state proximity plainly and explicitly: if locationScore
   is high, say this vendor was prioritized for being near the couple (name their location if given);
   if locationScore is low, say plainly that they're further away and that this weighed against them.
   Then, 1 sentence on style-tag fit with the couple's preferences.
4. "Verdict" — 1 short sentence final call, read like a planner's professional judgement, not a
   restatement of the numeric scores.

Then, ONLY for a category where you judged the couple's free-text note (above) to be both genuine and
actually applicable to that category, append a 5th step:
5. "Special request" — 1 short sentence starting with "You mentioned..." or "As you requested...",
   naming the specific thing the couple asked for and stating plainly how this vendor does or doesn't
   meet it. Omit this step entirely for every category the note doesn't genuinely apply to, and omit it
   everywhere if the note was rejected as not wedding-relevant.

Respond ONLY with valid JSON in this exact shape:
{
  "categories": {
    "<CategoryName>": {
      "vendorId": "...",
      "confidence": 0.0-1.0,
      "reasoningSteps": [
        { "label": "Budget fit", "text": "..." },
        { "label": "Availability", "text": "..." },
        { "label": "Style match", "text": "..." },
        { "label": "Verdict", "text": "..." },
        { "label": "Special request", "text": "..." }
      ]
    }
  }
}

Rules:
- Return exactly one entry per category key given above. vendorId MUST be copied verbatim from that
  exact category's list in CANDIDATE_VENDORS — never a vendorId from a different category, never a
  vendorId you constructed or modified, never a placeholder.
- confidence reflects how strongly you recommend this vendor to this couple specifically.
- reasoningSteps must always include the 4 required labels in order, each one short, specific sentence — no generic filler. Only add the 5th "Special request" step where it genuinely applies, per the rule above.
- Never invent facts — no prices, ratings, review counts, styles, or availability beyond what's given
  in CANDIDATE_VENDORS. Ground every claim only in that data, plus the couple's own free-text note
  where genuinely applicable. This is your single source of truth — treat anything not present in it
  as unknown, not as something you can estimate or fill in.
`;

  try {
    const json = await askGemini(prompt);
    res.json(json);
  } catch (err) {
    console.error('Gemini error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;

// A nodemon restart can race the previous process's socket release (Windows
// especially holds a killed process's port in TIME_WAIT briefly), so a fresh
// EADDRINUSE right after a restart doesn't necessarily mean another server is
// really running — retry briefly before giving up.
function startServer(retriesLeft = 5) {
  const server = app.listen(PORT, () => console.log(`WedPilot AI server listening on port ${PORT}`));

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE' && retriesLeft > 0) {
      console.warn(`Port ${PORT} still in use, retrying in 500ms... (${retriesLeft} attempts left)`);
      setTimeout(() => startServer(retriesLeft - 1), 500);
    } else if (err.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use. Please stop the existing process or set PORT to another value.`);
      process.exit(1);
    } else {
      console.error('Server startup failed:', err.message);
      process.exit(1);
    }
  });
}

sequelize
  .authenticate()
  // alter: true reconciles existing tables with the current models (adds
  // missing columns etc.) — there's no migrations setup yet, so a plain
  // sync() would silently leave older tables out of date with new model
  // fields and every write against them would fail.
  .then(() => sequelize.sync({ alter: true }))
  .then(() => {
    console.log('Database connected and synced.');
    startServer();
  })
  .catch((err) => {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  });

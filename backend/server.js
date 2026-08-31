require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { rateLimit, ipKeyGenerator } = require('express-rate-limit');
const sequelize = require('./db/sequelize');
const verifyJwt = require('./middleware/verifyJwt');
const { assertProductionConfig } = require('./config/requireEnv');
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

const IS_PRODUCTION = process.env.NODE_ENV === 'production';

// Before anything binds a port: every misconfiguration that would otherwise
// present as a working server with a quietly broken feature (mail that never
// sends, verification links pointing at localhost, an unusable signing key)
// becomes a refused start here. See config/requireEnv.js.
assertProductionConfig();

const app = express();

// Behind a PaaS load balancer every request arrives from the proxy, so
// express-rate-limit keys every caller to the same address and the auth /
// password-reset limiters throttle all users as if they were one. Trusting a
// single hop lets it read the real client IP from X-Forwarded-For. Left off
// outside production, where there is no proxy and trusting the header would
// let a caller spoof their own IP past the limiter.
if (IS_PRODUCTION) app.set('trust proxy', 1);

// Comma-separated list of origins allowed to call this API, e.g.
// "https://wedpilot.app,https://www.wedpilot.app". Required in production —
// a wide-open API is not something to fall back to silently. That requirement
// is enforced by assertProductionConfig above, alongside every other piece of
// config whose absence would otherwise present as a working server.
const allowedOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(cors({
  origin(origin, callback) {
    // No Origin header at all: native app builds, curl, server-to-server.
    // CORS is a browser mechanism — these were never subject to it, and
    // rejecting them here would break the Android and iOS clients.
    if (!origin) return callback(null, true);
    if (!IS_PRODUCTION || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error(`Origin ${origin} is not allowed by CORS.`));
  },
}));
// Baseline response headers: nosniff, no-referrer, frame denial, and (in
// production) HSTS. Two defaults are overridden below because this origin is
// a cross-origin API rather than a website.
app.use(helmet({
  // This process serves JSON and user-uploaded images — never HTML of its
  // own — so a global CSP would have no document to protect. The policy that
  // does matter is the hardened per-response one on /uploads below.
  contentSecurityPolicy: false,
  // The Flutter web build runs on its own origin (PUBLIC_WEB_BASE_URL) and
  // renders vendor/invitation images served from this one. helmet's default
  // same-origin CORP would make the browser block every one of those <img>
  // loads, so resources here are explicitly marked cross-origin readable.
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  // Only meaningful once TLS terminates in front of this process; sending it
  // over plain http in development would pin localhost to https in the
  // developer's browser and is genuinely annoying to undo.
  hsts: IS_PRODUCTION
    ? { maxAge: 31536000, includeSubDomains: true, preload: true }
    : false,
}));

app.use(express.json());

// Everything under here is user-supplied content. The uploader already
// rejects SVG and anything not matching an image/* mimetype (see
// middleware/upload.js), but that is one check against a hostile file and
// this is the path where a miss would be served straight back to a browser.
// The sandbox policy means that even if a file ever were rendered as a
// document it would run with no script, no plugins, and no same-origin
// identity of its own; helmet's nosniff (above) stops the browser
// re-interpreting a mislabelled file as HTML in the first place.
app.use(
  '/uploads',
  (_req, res, next) => {
    res.setHeader('Content-Security-Policy', "default-src 'none'; sandbox");
    next();
  },
  express.static(path.join(__dirname, 'uploads')),
);

// Backstop ceiling for the whole API. Auth, password-reset and AI endpoints
// each carry their own much tighter limiter; every other route — vendor
// search, messaging, budget writes, notification polling — had no ceiling at
// all before this, so a single scripted caller could saturate the database
// connection pool unopposed. Keyed on IP, which is coarse (a mobile carrier
// NAT shares one), so the limit is set well above what an app session can
// generate: a dashboard fanning out to a dozen endpoints on open still uses
// a tiny fraction of it, while a scripted loop hits it in seconds.
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please slow down and try again shortly.' },
});
app.use('/api', apiLimiter);

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

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_MODEL = 'nvidia/nemotron-3-ultra-550b-a55b:free';

// Every call here spends OpenRouter quota on our own key, so it is capped per
// account on top of requiring a session. The ceiling is deliberately generous
// against normal use — the matcher fires once per planning run, in the
// background — and only bites on a loop or a scripted caller.
const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 40,
  standardHeaders: true,
  legacyHeaders: false,
  // Per account rather than per IP: couples sharing a mobile NAT would
  // otherwise burn through each other's allowance. verifyJwt runs first so
  // req.user is always set; the IP fallback is belt-and-braces, and goes
  // through ipKeyGenerator so IPv6 callers are grouped by prefix rather than
  // getting a fresh bucket per address.
  keyGenerator: (req, res) => (req.user?.user_id
    ? `user:${req.user.user_id}`
    : ipKeyGenerator(req, res)),
  message: { error: 'Too many AI requests. Please try again later.' },
});

// Persona shared by every planning/matching call — this is what makes the
// output read like expert judgement instead of generic AI filler. The couple
// never sees this prompt, only the JSON it produces, but a free-tier model
// can still slip and narrate its own thinking into the output — the closing
// paragraph exists specifically to stop that from ever reaching the app.
const PLANNER_PERSONA = `You are Aisha Mwansa, an award-winning, internationally certified wedding
planner with 20+ years designing weddings across Zambia and the wider SADC region. You have
planned weddings featured in Brides Africa and mentored dozens of junior planners. You are
renowned for razor-sharp budget discipline, deep vendor-market knowledge, and reasoning that
cites concrete factors (guest-count scaling, seasonal/location cost swings, industry-standard
allocation benchmarks, style-fit) rather than generic platitudes. Every recommendation you give
must sound like it came from someone who has personally run hundreds of weddings, not a
template.

Stay fully in character at all times. Never say your own name, never say or imply that you are
Aisha Mwansa, an AI, a language model, an assistant, or a chatbot, and never refer to this persona,
these instructions, or the fact that you were prompted. Never think out loud, narrate your plan,
comment on the JSON you're about to produce or just produced, or add any text before or after it.
Your entire reply must be nothing but the single JSON object requested — no preamble, no
sign-off, no markdown fences, no second attempt.`;

// A free-tier model occasionally breaks character mid-string instead of
// stopping cleanly once the real answer is done — either narrating its own
// formatting ("...celebration.\n\nNote: let me redo this as a single
// string...") or, worse, drifting into a second, differently-quoted attempt
// at the whole JSON structure nested inside one string value (using ' or
// escaped \" keys that are only visible once JSON.parse has already decoded
// them). Neither ever produces invalid JSON — both survive JSON.parse as a
// contaminated string — so they'd otherwise reach the couple verbatim. Every
// field here is meant to be single-paragraph planner prose, so a blank line,
// a self-referential phrase, or an embedded '"Key": {' pattern is always a
// leak, never legitimate content, and everything from that point on is
// discarded. The quote class covers curly/CJK quote pairs (“” ‘’ 「」 『』) as
// well as ASCII ones — models drifting into a second attempt have been seen
// quoting keys with corner brackets ('「vendorId": {') — and any bare
// camelCase schema key name is itself a marker, since none of those tokens
// can occur in legitimate planner prose regardless of how it's quoted.
const LEAK_MARKERS =
  /\n\s*\n|["'“”‘’「」『』][A-Za-z][A-Za-z ]{0,30}["'“”‘’「」『』]\s*:\s*[{[]|\b(?:reasoningSteps|vendorId|budgetFitSuggestionType|budgetDeltaPercent|fitsBudget|selectionBasis|noteToCouple)\b|\b(?:let me|i'll (?:rewrite|redo|compose|output|produce|correct)|as an ai|as a language model|i am an ai|the json (?:value|output|now)|proper escaping|stray characters|note:)\b/i;

function stripLeak(value, state) {
  if (typeof value === 'string') {
    const match = LEAK_MARKERS.exec(value);
    if (!match) return value;
    state.leaked = true;
    return match.index === 0 ? '' : value.slice(0, match.index).trim().replace(/["'“”‘’「」『』{,:]+$/, '').trim();
  }
  if (Array.isArray(value)) return value.map((v) => stripLeak(v, state));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, stripLeak(v, state)]));
  }
  return value;
}

// A single attempt meant any transient failure — the free-tier model's
// shared 429 rate limit being the most common cause — produced no plan/match
// at all, forcing the Flutter client's local fallback every time OpenRouter
// so much as hiccups. Retrying a bounded number of times with backoff trades
// a little latency for landing the real AI path far more often, while still
// failing fast on anything a retry can't fix (bad key, malformed request).
const MAX_AI_ATTEMPTS = 3;

// Worth retrying: 429 (rate limit) and any 5xx (transient upstream fault).
// Everything else (400/401/402/403/404...) is a property of the request or
// credentials themselves — retrying with the same body and key can't change
// the outcome, so those fail fast instead of burning the attempt budget.
function isRetryableStatus(status) {
  return status === 429 || status >= 500;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Both endpoints ask for JSON in the prompt itself and extract the first
// {...} span from the response text (response_format is a hint, not a
// guarantee, on every OpenRouter model). reasoning.exclude keeps a
// reasoning-capable model's chain-of-thought out of the returned content
// entirely, and stripping any stray <think> block is a second line of
// defense for models that ignore that flag. `validate` lets each caller
// reject a structurally broken result (e.g. the real fields never showed up
// because the model dumped everything into one narrated string) so a retry
// gets attempted instead of silently shipping an incomplete plan.
async function askAI(prompt, validate = () => true) {
  let lastResult = null;
  let lastError = null;

  for (let attempt = 0; attempt < MAX_AI_ATTEMPTS; attempt++) {
    if (attempt > 0) {
      console.warn(`OpenRouter retry ${attempt + 1}/${MAX_AI_ATTEMPTS} after: ${lastError?.message}`);
      await sleep(400 * attempt);
    }

    let res;
    try {
      res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${OPENROUTER_API_KEY}`,
        },
        body: JSON.stringify({
          model: OPENROUTER_MODEL,
          messages: [
            { role: 'system', content: PLANNER_PERSONA },
            { role: 'user', content: prompt },
          ],
          response_format: { type: 'json_object' },
          reasoning: { exclude: true },
        }),
      });
    } catch (networkErr) {
      // fetch() rejects on a true network-level failure (DNS/TLS/reset) —
      // just as transient as a 429/5xx, so it gets the same retry treatment.
      lastError = networkErr;
      continue;
    }

    if (!res.ok) {
      const errText = await res.text();
      // Surface OpenRouter's own message verbatim rather than our own
      // wrapper text — the couple should see exactly what the AI service
      // said (e.g. its real rate-limit wording), not a paraphrase. Most
      // providers return {"error": {"message": "...", ...}} or
      // {"message": "..."}; fall back to the raw body only when it isn't
      // JSON at all (never fabricate a message that didn't come from them).
      let upstreamMessage = errText;
      try {
        const parsedErr = JSON.parse(errText);
        upstreamMessage = parsedErr?.error?.message || parsedErr?.message || errText;
      } catch {
        // Not JSON — errText itself is already the best available message.
      }
      lastError = new Error(upstreamMessage);
      lastError.status = res.status;
      if (!isRetryableStatus(res.status)) throw lastError;
      continue;
    }

    const data = await res.json();
    const rawText = data.choices?.[0]?.message?.content ?? '';
    const text = rawText.replace(/<think>[\s\S]*?<\/think>/gi, '');
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    let parsed;
    try {
      parsed = JSON.parse(text.substring(start, end + 1));
    } catch {
      lastError = new Error('AI returned a response that could not be understood.');
      continue; // malformed JSON entirely — worth a retry before giving up
    }

    const sanitized = stripLeak(parsed, { leaked: false });
    lastResult = sanitized;
    if (validate(sanitized)) return sanitized;
  }

  if (lastResult === null) {
    // Surface the real cause when every attempt failed at the HTTP/network
    // level (lets the client tell "rate limited" from "unreachable" apart);
    // only fall back to the generic message when attempts got JSON back but
    // it was never parseable/valid. Never forward raw model text to the
    // client either way — it may contain leaked meta-commentary.
    throw lastError ?? new Error('AI returned a response that could not be understood. Please try again.');
  }
  // Every attempt was sanitized (never raw leaked text) but never fully
  // validated — return the last one anyway rather than hard-failing the
  // couple's request over an incomplete-but-still-usable plan.
  return lastResult;
}

// The 4 reasoning steps every vendor-match category must always carry (see the
// prompt below). "Budget fit" isn't in this list because the app writes that
// step entirely itself (see groundedBudgetFitText) — the model only
// contributes budgetFitSuggestionType.
const REQUIRED_REASONING_LABELS = ['Reputation', 'Availability', 'Style match', 'Verdict'];

const BUDGET_FIT_SUGGESTION_TYPES = ['negotiate', 'trim_scope', 'reallocate_budget', 'none_needed'];

const BUDGET_CLASS_DISPLAY_NAMES = {
  highClass: 'High Class',
  flexible: 'Flexible',
  budgetFriendly: 'Budget-Friendly',
};

const BUDGET_FIT_SUGGESTION_CLAUSES = {
  negotiate: 'asking for a smaller or custom package',
  trim_scope: 'trimming the scope for this category',
  reallocate_budget: 'shifting some budget over from a lower-priority category',
};

// The prompt tells the model to copy rating/feedbackCount/isBookedOnWeddingDate
// into these two steps "exactly, character-for-character" — but nothing stops
// a free-tier model from drifting, especially on a retry-exhausted response
// (see askAI's "return the last one anyway" fallback above). Rewriting these
// two steps from the same candidate object the model was given closes that
// gap for good: the couple can never see a star rating, review count, or
// availability claim that didn't come from the real vendor record — the same
// guarantee the vendorId check already gives vendor identity, extended to
// vendor facts. Style match and Verdict stay as the model wrote them — those
// are legitimate planner judgement calls, not copyable facts.
function groundedStepText(label, candidate) {
  if (label === 'Reputation') {
    const rating = typeof candidate.rating === 'number' ? candidate.rating : null;
    const feedbackCount = candidate.feedbackCount ?? 0;
    if (rating === null || feedbackCount === 0) return 'New to WedPilot — no client ratings yet.';
    return `${rating.toFixed(1)}★ from ${feedbackCount} verified ${feedbackCount === 1 ? 'client' : 'clients'}.`;
  }
  if (label === 'Availability') {
    return candidate.isBookedOnWeddingDate
      ? 'Already appears booked on your wedding date — confirm availability before committing, or line up a backup.'
      : 'Open on your wedding date, based on their calendar.';
  }
  return null;
}

// The model only ever contributes a qualitative suggestionType for this step
// (see the prompt) — every number in the sentence itself (price, budget,
// delta percent) is inserted here from the real candidate/budget data, so a
// "you're X% over budget" claim can never drift from what the app itself
// just computed two lines above.
function groundedBudgetFitText(cat, budget, priceMin, fitsBudget, budgetDeltaPercent, suggestionType) {
  if (budget == null) {
    return `No specific allocation set for ${cat} yet, so price wasn't used as a filter here.`;
  }
  if (fitsBudget) {
    return `Fits within your ~${budget.toFixed(0)} allocation for ${cat}.`;
  }
  const clause = BUDGET_FIT_SUGGESTION_CLAUSES[suggestionType] || BUDGET_FIT_SUGGESTION_CLAUSES.reallocate_budget;
  return `Starts around ${priceMin.toFixed(0)}, about ${budgetDeltaPercent}% over your ~${budget.toFixed(0)} budget for ${cat} — still the closest available fit. You can move forward by ${clause}.`;
}

function groundedNoteToCouple(cat, budgetClass, fitsBudget, budgetDeltaPercent) {
  if (fitsBudget) return `Fits your allocated budget for ${cat}.`;
  const tierName = (BUDGET_CLASS_DISPLAY_NAMES[budgetClass] || 'Flexible').toLowerCase();
  const deltaClause = budgetDeltaPercent != null ? ` — about ${budgetDeltaPercent}% over your allocation` : '';
  return `No ${tierName} pick fit your budget for ${cat} exactly, so this is the closest match for that tier${deltaClause}.`;
}

function groundVendorMatch(json, picks, categoryBudgets, budgetClass) {
  for (const [cat, entry] of Object.entries(json.categories || {})) {
    const candidate = picks[cat];
    if (!candidate) continue; // no matching pick was sent for this category

    const budget = categoryBudgets[cat];
    const priceMin = candidate.priceMin ?? 0;
    const fitsBudget = budget == null || priceMin <= budget;
    const budgetDeltaPercent = fitsBudget ? null : Math.round(((priceMin - budget) / budget) * 100);
    entry.fitsBudget = fitsBudget;
    entry.budgetDeltaPercent = budgetDeltaPercent;
    entry.selectionBasis = fitsBudget ? 'exact_budget_match' : 'wedding_class_best_fit';
    entry.noteToCouple = groundedNoteToCouple(cat, budgetClass, fitsBudget, budgetDeltaPercent);

    const budgetFitStep = {
      label: 'Budget fit',
      text: groundedBudgetFitText(cat, budget, priceMin, fitsBudget, budgetDeltaPercent, entry.budgetFitSuggestionType),
    };
    const otherSteps = (Array.isArray(entry.reasoningSteps) ? entry.reasoningSteps : [])
      .filter((step) => step.label !== 'Budget fit')
      .map((step) => {
        const text = groundedStepText(step.label, candidate);
        return text === null ? step : { ...step, text };
      });
    entry.reasoningSteps = [budgetFitStep, ...otherSteps];
  }
  return json;
}

// ── POST /api/vendor-match ────────────────────────────────────────────────────
// The winning vendor per category is already decided before this endpoint is
// ever called — see _AiEngine.recommend in vendor_ai_provider.dart, which
// scores and ranks the whole pool deterministically, in-process, in single-
// digit milliseconds. The AI's only remaining job is writing warm,
// human-readable justification for a pick it can no longer change — it never
// searches, filters, scores, or chooses between candidates. Flutter calls
// this in the background, after the couple already sees their matches, so a
// slow or failed AI response never blocks or delays a result.
app.post('/api/vendor-match', verifyJwt, aiLimiter, async (req, res) => {
  const t0 = Date.now();
  const {
    budgetClass = 'flexible', location = null, styles = [], picks = {}, categoryBudgets = {},
  } = req.body;
  const requestedCategories = Object.keys(picks);

  const prompt = `
You're writing warm, professional justification notes for a wedding planner. The planner has
ALREADY chosen the best vendor in each category below — your only job is to explain, in your own
words, why each pick is a strong choice for this couple. Never second-guess the pick, never suggest
a different vendor, never imply another option was considered.

Couple context:
- Budget class: ${budgetClass}
- Location: ${location ?? 'Not specified'}
- Style preferences: ${styles.length ? styles.join(', ') : 'Not specified'}
- Allocated budget per category (their money, in local currency; a category absent here has no known cap):
${JSON.stringify(categoryBudgets)}

CHOSEN_VENDORS — one already-decided vendor per category, grouped by category (JSON). Each carries
three precomputed 0-1 signal scores: reputationScore (rating/reviews/track record), locationScore
(proximity to the couple), valueScore (price fit against the couple's allocated budget), plus
priceMin/priceMax/priceTier and an isBookedOnWeddingDate flag (true = a confirmed booking already
sits on the couple's wedding date):
${JSON.stringify(picks)}

Every businessName, style tag, and fact you reference must be copied exactly, character-for-character,
from this data — never invent, alter, guess, or reference a vendor that isn't listed here. If you are
ever unsure whether a value came from CHOSEN_VENDORS, do not state it.

The app — not you — computes and displays the exact price, percentage-over-budget, rating, review
count, and availability figures, because those must always match the database exactly. So: set
budgetFitSuggestionType to exactly one of "negotiate" (price is close enough that a trimmed custom
package is realistic), "trim_scope" (better to reduce what this category covers), "reallocate_budget"
(better to shift budget from a lower-priority category), or "none_needed" (the pick already fits
within its allocated budget, or no allocated budget was given for this category) — judge this from
priceMin against the allocated budget above. Never state a specific price, percentage, rating,
review count, or booked/available status anywhere in your reasoning text for any step below —
describe situations qualitatively only; the app fills in every figure itself.

Instead of one run-on explanation, break your justification for each pick into named, ordered steps
(like a planner walking through their checklist one line at a time). Always include these four:
1. "Reputation" — 1 short sentence on how strong this vendor's track record is, qualitatively (e.g.
   "well-reviewed and trusted" vs "new to the platform, unproven yet") — no numbers.
2. "Availability" — 1 short sentence on whether the couple should treat this vendor as available or
   should double-check, qualitatively — no restating true/false or specific dates.
3. "Style match" — 2 short sentences. First, state proximity plainly and explicitly: if locationScore
   is high, say this vendor was prioritized for being near the couple (name their location if given);
   if locationScore is low, say plainly that they're further away and that this weighed against them.
   Then, 1 sentence on style-tag fit with the couple's preferences.
4. "Verdict" — 1 short sentence final call, read like a planner's professional judgement, not a
   restatement of the numeric scores.

Respond ONLY with valid JSON in this exact shape:
{
  "categories": {
    "<CategoryName>": {
      "confidence": 0.0-1.0,
      "budgetFitSuggestionType": "negotiate" | "trim_scope" | "reallocate_budget" | "none_needed",
      "reasoningSteps": [
        { "label": "Reputation", "text": "..." },
        { "label": "Availability", "text": "..." },
        { "label": "Style match", "text": "..." },
        { "label": "Verdict", "text": "..." }
      ]
    }
  }
}

Rules:
- Return exactly one entry per category key given above — no vendorId field, the app already knows it.
- confidence reflects how strongly you'd back this pick to this couple specifically.
- reasoningSteps must always include all 4 required labels in order, each one short, specific sentence — no generic filler.
- Never invent facts — no prices, ratings, review counts, styles, or availability beyond what's given
  in CHOSEN_VENDORS. Ground every claim only in that data.
`;

  // Requiring the 4 reasoning labels plus a valid budgetFitSuggestionType
  // documents what a "good" response looks like — a failed check here spends
  // one of MAX_AI_ATTEMPTS retries, and if every attempt still fails it, the
  // Flutter side simply keeps the deterministic reasoning it already shipped
  // with (see _backfillAiExplanations's catch block).
  // The prompt forbids the model from stating any figure — the app inserts
  // every real number itself. "Reputation"/"Availability" get rewritten from
  // the candidate record regardless (see groundedStepText), but "Style match"
  // and "Verdict" ship as the model wrote them, so a fabricated "95% match"
  // or "4.8★" or a price-sized number there fails the whole response.
  const FABRICATED_FIGURE = /\d+(?:\.\d+)?\s*(?:%|★)|\b\d{3,}\b/;
  const MODEL_AUTHORED_LABELS = ['Style match', 'Verdict'];

  const validate = (r) =>
    r.categories &&
    typeof r.categories === 'object' &&
    requestedCategories.every((cat) => {
      const entry = r.categories[cat];
      if (!entry) return false;
      if (!BUDGET_FIT_SUGGESTION_TYPES.includes(entry.budgetFitSuggestionType)) return false;
      const steps = Array.isArray(entry.reasoningSteps) ? entry.reasoningSteps : [];
      const labels = new Set(steps.map((s) => s.label));
      if (!REQUIRED_REASONING_LABELS.every((label) => labels.has(label))) return false;
      return steps.every(
        (s) => !MODEL_AUTHORED_LABELS.includes(s.label) || !FABRICATED_FIGURE.test(String(s.text)),
      );
    });

  const tPromptBuilt = Date.now();
  try {
    const json = await askAI(prompt, validate);
    const tAiDone = Date.now();
    // The model was never given a vendorId to echo back — inject the real one
    // ourselves so groundVendorMatch (and the Flutter response parser, which
    // requires it) never depends on the model getting an identifier right.
    for (const [cat, entry] of Object.entries(json.categories || {})) {
      if (picks[cat]) entry.vendorId = picks[cat].vendorId;
    }
    groundVendorMatch(json, picks, categoryBudgets, budgetClass);
    console.log(
      `[timing] /api/vendor-match — explanations for ${requestedCategories.length} categories — `
      + `prompt build ${tPromptBuilt - t0}ms, AI request ${tAiDone - tPromptBuilt}ms, grounding ${Date.now() - tAiDone}ms, `
      + `total ${Date.now() - t0}ms`,
    );
    res.json(json);
  } catch (err) {
    console.error(`OpenRouter AI error after ${Date.now() - t0}ms:`, err.message);
    res.status(err.status ?? 500).json({ error: err.message });
  }
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

// Static, human-readable legal pages — required by Google's OAuth consent
// screen (Application privacy policy link / terms of service link) before
// the app can be published for sign-in beyond the listed test users.
app.get('/privacy-policy', (_, res) => res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html')));
app.get('/terms-of-service', (_, res) => res.sendFile(path.join(__dirname, 'public', 'terms-of-service.html')));

// Every route above already wraps its own body in try/catch and returns a
// clean JSON error — these two exist only to catch what's outside that: a
// request for a route that doesn't exist, a synchronous throw a handler
// forgot to guard, or (most commonly) express.json() rejecting a malformed
// request body before any route handler even runs.
app.use((req, res) => {
  res.status(404).json({ error: 'Not found.' });
});

// Must be registered last and take all 4 arguments — that arity is what
// tells Express this is an error handler rather than another route.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(`Unhandled error on ${req.method} ${req.originalUrl}:`, err);
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Malformed request body.' });
  }
  // The real error is always logged server-side above — the client only
  // ever gets err.message in development, never a stack trace, and gets a
  // fully generic message in production so an unexpected failure mode can
  // never describe the app's own internals to whoever triggered it.
  const message = process.env.NODE_ENV === 'production'
    ? 'Something went wrong. Please try again.'
    : err.message || 'Something went wrong.';
  res.status(err.status ?? err.statusCode ?? 500).json({ error: message });
});

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

// Production schema is owned by backend/migrations, applied by
// `npm run migrate` as a release step — never by the server on boot.
// `sync({ alter: true })` rewrites live tables to match the models every
// restart, and on MySQL a column type change is a drop-and-recreate, so it
// would quietly destroy production data. It stays on in development, where
// the convenience is worth it and the database is disposable.
sequelize
  .authenticate()
  .then(() => (IS_PRODUCTION ? Promise.resolve() : sequelize.sync({ alter: true })))
  .then(() => {
    console.log(
      IS_PRODUCTION
        ? 'Database connected (schema managed by migrations).'
        : 'Database connected and synced.',
    );
    startServer();
  })
  .catch((err) => {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  });

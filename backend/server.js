require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const Groq = require('groq-sdk');
const sequelize = require('./db/sequelize');
require('./db/models/user');
require('./db/models/coupleProfile');
require('./db/models/task');
require('./db/models/vendor');
require('./db/models/vendorService');
require('./db/models/vendorMedia');
require('./db/models/review');
require('./db/models/inquiry');
require('./db/models/savedVendor');
require('./db/models/budget');
require('./db/models/budgetCategory');
require('./db/models/budgetCustomItem');
require('./db/models/expense');
const authRoutes = require('./routes/auth');
const coupleProfileRoutes = require('./routes/coupleProfile');
const taskRoutes = require('./routes/tasks');
const vendorRoutes = require('./routes/vendors');
const wishlistRoutes = require('./routes/wishlist');
const budgetRoutes = require('./routes/budget');

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

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const GROQ_MODEL = 'llama-3.1-8b-instant';

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
You are an expert wedding planning AI assistant for WedPilot, a wedding app used in Zambia.

A couple is planning their wedding:
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

Respond ONLY with valid JSON:
{
  "planSummary": "A warm, encouraging 2-3 sentence personalised summary. Mention location, budget and date if set. Be uplifting and specific to their choices.",
  "budgetAdvice": { "CategoryName": percentage_number },
  "vendorReasonings": { "CategoryName": "One sentence why this vendor suits this couple." }
}

Rules:
- budgetAdvice must cover every category in [${categoriesStr}] and sum to exactly 100.
- Use plain numbers for percentages (e.g. 30, not "30%").
- vendorReasonings must cover every category that has a top vendor listed.
- Friendly, professional tone suited to a Zambian wedding market.
`;

  try {
    const completion = await groq.chat.completions.create({
      model: GROQ_MODEL,
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
    });
    const text = completion.choices[0].message.content;
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    const json = JSON.parse(text.substring(start, end + 1));
    res.json(json);
  } catch (err) {
    console.error('Groq error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/vendor-match ────────────────────────────────────────────────────
app.post('/api/vendor-match', async (req, res) => {
  const { budgetClass = 'flexible', location = null, styles = [], categories = {} } = req.body;

  const prompt = `
You are an expert wedding vendor-matching AI for WedPilot, a wedding app used in Zambia.

Couple context:
- Budget class: ${budgetClass}
- Location: ${location ?? 'Not specified'}
- Style preferences: ${styles.length ? styles.join(', ') : 'Not specified'}

For each category below, you are given a pre-filtered candidate list. Each candidate already
passed eligibility rules and has three precomputed 0-1 signal scores: reputationScore (rating/
reviews/track record), locationScore (proximity to the couple), valueScore (price fit for their
budget class). Use these as inputs, but make your own holistic judgement — factor in style tag
overlap with the couple's preferences and each vendor's profile — then pick the single best
vendor per category and write genuine, specific reasoning for that pick.

Candidates by category (JSON):
${JSON.stringify(categories, null, 2)}

Respond ONLY with valid JSON in this exact shape:
{
  "categories": {
    "<CategoryName>": { "vendorId": "...", "confidence": 0.0-1.0, "reasoning": "one sentence, specific to this couple" }
  }
}

Rules:
- Return exactly one entry per category key given above, using a vendorId from that category's candidate list.
- confidence reflects how strongly you recommend this vendor to this couple specifically.
- reasoning must be specific (mention style/location/budget fit) — do not just restate the numeric scores.
`;

  try {
    const completion = await groq.chat.completions.create({
      model: GROQ_MODEL,
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
    });
    const text = completion.choices[0].message.content;
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    const json = JSON.parse(text.substring(start, end + 1));
    res.json(json);
  } catch (err) {
    console.error('Groq error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;

sequelize
  .authenticate()
  // alter: true reconciles existing tables with the current models (adds
  // missing columns etc.) — there's no migrations setup yet, so a plain
  // sync() would silently leave older tables out of date with new model
  // fields and every write against them would fail.
  .then(() => sequelize.sync({ alter: true }))
  .then(() => {
    console.log('Database connected and synced.');
    app.listen(PORT, () => console.log(`WedPilot AI server listening on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  });

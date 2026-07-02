require('dotenv').config();
const express = require('express');
const cors = require('cors');
const Groq = require('groq-sdk');
const sequelize = require('./db/sequelize');
require('./db/models/user');
require('./db/models/coupleProfile');
const authRoutes = require('./routes/auth');
const coupleProfileRoutes = require('./routes/coupleProfile');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/couple', coupleProfileRoutes);

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

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;

sequelize
  .authenticate()
  .then(() => sequelize.sync())
  .then(() => {
    console.log('Database connected and synced.');
    app.listen(PORT, () => console.log(`WedPilot AI server listening on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  });

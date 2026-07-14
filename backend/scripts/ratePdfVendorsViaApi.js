// Third follow-up to addPdfVendorsViaApi.js — still entirely through the
// real public HTTP API, not direct DB writes: real couple accounts send a
// real inquiry, the vendor accepts and marks it done, then the couple
// submits real feedback. This is the exact 4-step handshake the app itself
// enforces (see backend/routes/vendors.js: POST /:id/inquiries, PATCH
// /me/inquiries/:id, POST /me/inquiries/:id/service-done, POST
// /:id/feedback) — nothing here bypasses it.
//
// Rates the first 5 (by rank) vendors in each of the 8 categories — 40
// vendors, minus kabaso@gmail.com (still unreachable) = 39 rated. Assigned
// to high/mid/low reputation tiers round-robin across the 40 slots so each
// tier gets an even share:
//   high -> 5 stars (lands in the app's "strong reputation" bucket, >=4.0)
//   mid  -> 3 stars (lands in "lower reputation", <4.0)
//   low  -> 1 star  (also "lower reputation", <4.0 — the app only has two
//                     rated buckets; mid/low differ in raw rating, not bucket)
//
// A small shared pool of 8 real couple accounts (password 12345678) rates
// across categories, same pattern as the app's own booking flow — a couple
// can rate many different vendors, just not the same vendor twice.
//
// Requires the backend server to already be running. Usage:
// node scripts/ratePdfVendorsViaApi.js
require('dotenv').config();

const API_BASE = process.env.API_BASE || 'http://localhost:3000';
const PASSWORD = '12345678';
const COUPLE_COUNT = 8;

const CATEGORIES = {
  Venue: ['Mwansa Zulu|mwansa@gmail.com', 'Bwalya Phiri|bwalya@gmail.com', 'Chileshe Tembo|chileshe@gmail.com', 'Mulenga Banda|mulenga@gmail.com', 'Chanda Mumba|chanda@gmail.com'],
  Catering: ['Namwinga Ngoma|namwinga@gmail.com', 'Nchimunya Lungu|nchimunya@gmail.com', 'Kabaso Chulu|kabaso@gmail.com', 'Chibale Malama|chibale@gmail.com', 'Yamikani Simfukwe|yamikani@gmail.com'],
  Photography: ['Nawa Chisha|nawa@gmail.com', 'Kaonga Lubinda|kaonga@gmail.com', 'Chibwe Chitalu|chibwe@gmail.com', 'Mwenya Situmbeko|mwenya@gmail.com', 'Kalima Chishimba|kalima@gmail.com'],
  'Decor & flowers': ['Chibiya Chomba|chibiya@gmail.com', 'Milambo Chishala|milambo@gmail.com', 'Namuchana Chisenga|namuchana@gmail.com', 'Kabwe Kayula|kabwe@gmail.com', 'Mundia Chishiba|mundia@gmail.com'],
  'DJ & MC': ['Kondwani Mwewa|kondwani@gmail.com', 'Emmanuel Sinkala|emmanuel@gmail.com', 'Given Musukwa|given@gmail.com', 'Blessings Chibuye|blessings@gmail.com', 'Ackim Kalenga|ackim@gmail.com'],
  Transport: ['Justin Nkonde|justin@gmail.com', 'Boniface Mulele|boniface@gmail.com', 'Christopher Njobvu|christopher@gmail.com', 'Prisca Sitali|prisca@gmail.com', 'Gift Miti|gift@gmail.com'],
  'Wedding attire': ['Miyoba Phiri|miyoba@gmail.com', 'Chrispin Tembo|chrispin@gmail.com', 'Chishimba Banda|chishimba@gmail.com', 'Fredrick Mumba|fredrick@gmail.com', 'Precious Sakala|precious@gmail.com'],
  'Cake & sweets': ['Inutu Zulu|inutu@gmail.com', 'Malama Phiri|malama@gmail.com', 'Bupe Tembo|bupe@gmail.com', 'Chilufya Banda|chilufya@gmail.com', 'Simfukwe Mumba|simfukwe@gmail.com'],
};

const TIERS = [
  { name: 'high', stars: 5, on_time: 'yes' },
  { name: 'mid', stars: 3, on_time: 'not_applicable' },
  { name: 'low', stars: 1, on_time: 'no' },
];

async function api(path, { method = 'GET', token, body } = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = res.status === 204 ? {} : await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data };
}

async function loginOrRegisterCouple(index) {
  const email = `rate-couple-${String(index).padStart(2, '0')}@wedpilot.test`;
  const name = `Rate Couple ${index}`;
  const registerRes = await api('/api/auth/register', {
    method: 'POST',
    body: { email, password: PASSWORD, name, role: 'couple' },
  });
  if (registerRes.ok) return { email, token: registerRes.data.accessToken };
  const loginRes = await api('/api/auth/login', { method: 'POST', body: { email, password: PASSWORD } });
  if (!loginRes.ok) throw new Error(`Could not get couple ${email}: ${JSON.stringify(loginRes.data)}`);
  return { email, token: loginRes.data.accessToken };
}

async function rateVendor(vendorName, vendorEmail, tier, coupleToken, coupleEmail) {
  const loginRes = await api('/api/auth/login', { method: 'POST', body: { email: vendorEmail, password: PASSWORD } });
  if (!loginRes.ok) {
    console.error(`  SKIP ${vendorName}: vendor login failed — ${JSON.stringify(loginRes.data)}`);
    return false;
  }
  const vendorToken = loginRes.data.accessToken;

  const meRes = await api('/api/vendors/me', { token: vendorToken });
  if (!meRes.ok) {
    console.error(`  SKIP ${vendorName}: could not load vendor profile — ${JSON.stringify(meRes.data)}`);
    return false;
  }
  const vendorId = meRes.data.vendor.vendor_id;

  const inquiryRes = await api(`/api/vendors/${vendorId}/inquiries`, {
    method: 'POST',
    token: coupleToken,
    body: { message: `Hi ${vendorName}, we'd love to book you for our wedding!` },
  });
  if (!inquiryRes.ok) {
    console.error(`  SKIP ${vendorName}: inquiry failed — ${JSON.stringify(inquiryRes.data)}`);
    return false;
  }
  const inquiryId = inquiryRes.data.inquiry.inquiry_id;

  const bookRes = await api(`/api/vendors/me/inquiries/${inquiryId}`, {
    method: 'PATCH',
    token: vendorToken,
    body: { status: 'booked' },
  });
  if (!bookRes.ok) {
    console.error(`  SKIP ${vendorName}: vendor accept failed — ${JSON.stringify(bookRes.data)}`);
    return false;
  }

  const doneRes = await api(`/api/vendors/me/inquiries/${inquiryId}/service-done`, {
    method: 'POST',
    token: vendorToken,
  });
  if (!doneRes.ok) {
    console.error(`  SKIP ${vendorName}: mark-service-done failed — ${JSON.stringify(doneRes.data)}`);
    return false;
  }

  const feedbackRes = await api(`/api/vendors/${vendorId}/feedback`, {
    method: 'POST',
    token: coupleToken,
    body: { star_rating: tier.stars, on_time: tier.on_time },
  });
  if (!feedbackRes.ok) {
    console.error(`  SKIP ${vendorName}: feedback failed — ${JSON.stringify(feedbackRes.data)}`);
    return false;
  }

  console.log(`  OK ${vendorName} — ${tier.stars}★ (${tier.name}) rated by ${coupleEmail}`);
  return true;
}

async function main() {
  const health = await fetch(`${API_BASE}/health`).catch(() => null);
  if (!health || !health.ok) {
    console.error(`Backend not reachable at ${API_BASE} — start it first (node server.js).`);
    process.exit(1);
  }

  const couples = [];
  for (let i = 1; i <= COUPLE_COUNT; i++) couples.push(await loginOrRegisterCouple(i));
  console.log(`Ready ${couples.length} couple accounts.\n`);

  let globalIndex = 0;
  const tally = { high: 0, mid: 0, low: 0 };
  for (const [category, vendors] of Object.entries(CATEGORIES)) {
    console.log(`${category}:`);
    for (const entry of vendors) {
      const [name, email] = entry.split('|');
      if (email === 'kabaso@gmail.com') {
        console.log(`  SKIP ${name}: account still not reachable with shared password.`);
        globalIndex++;
        continue;
      }
      const tier = TIERS[globalIndex % 3];
      const couple = couples[globalIndex % couples.length];
      const ok = await rateVendor(name, email, tier, couple.token, couple.email);
      if (ok) tally[tier.name]++;
      globalIndex++;
    }
    console.log('');
  }

  console.log(`Done. high=${tally.high}, mid=${tally.mid}, low=${tally.low}, total=${tally.high + tally.mid + tally.low}`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Rating run failed:', err.message);
  process.exit(1);
});

// Second follow-up to addPdfVendorsViaApi.js — still goes through the real
// public HTTP API (login + PUT /api/vendors/me), not direct DB writes.
//
// The PDF source gave no location per vendor, so none was set on the
// original import. Per explicit instruction, this assigns a mix of Kitwe
// and Ndola (real Zambian Copperbelt cities, real coordinates) alternating
// by each vendor's 1-10 rank within their category (odd rank -> Kitwe, even
// rank -> Ndola) — an explicit, disclosed assignment, not a claim that this
// is where each vendor actually operates.
//
// kabaso@gmail.com is skipped — still not reachable with the shared password.
//
// Requires the backend server to already be running. Usage:
// node scripts/updatePdfVendorLocationsViaApi.js
require('dotenv').config();

const API_BASE = process.env.API_BASE || 'http://localhost:3000';
const PASSWORD = '12345678';

const CITIES = {
  Kitwe: { latitude: -12.8024, longitude: 28.2132 },
  Ndola: { latitude: -12.9587, longitude: 28.6366 },
};

const CATEGORIES = {
  Venue: ['Mwansa Zulu|mwansa@gmail.com', 'Bwalya Phiri|bwalya@gmail.com', 'Chileshe Tembo|chileshe@gmail.com', 'Mulenga Banda|mulenga@gmail.com', 'Chanda Mumba|chanda@gmail.com', 'Kaluba Sakala|kaluba@gmail.com', 'Nkole Daka|nkole@gmail.com', 'Musonda Kunda|musonda@gmail.com', 'Chungu Mwape|chungu@gmail.com', 'Chipego Kangwa|chipego@gmail.com'],
  Catering: ['Namwinga Ngoma|namwinga@gmail.com', 'Nchimunya Lungu|nchimunya@gmail.com', 'Kabaso Chulu|kabaso@gmail.com', 'Chibale Malama|chibale@gmail.com', 'Yamikani Simfukwe|yamikani@gmail.com', 'Katongo Mutinta|katongo@gmail.com', 'Sepiso Inutu|sepiso@gmail.com', 'Namakau Mapalo|namakau@gmail.com', 'Twaambo Mwaba|twaambo@gmail.com', 'Chola Mutale|chola@gmail.com'],
  Photography: ['Nawa Chisha|nawa@gmail.com', 'Kaonga Lubinda|kaonga@gmail.com', 'Chibwe Chitalu|chibwe@gmail.com', 'Mwenya Situmbeko|mwenya@gmail.com', 'Kalima Chishimba|kalima@gmail.com', 'Ngandu Musunga|ngandu@gmail.com', 'Kalaba Mubanga|kalaba@gmail.com', 'Chikwanda Musanje|chikwanda@gmail.com', 'Nsofu Kaseba|nsofu@gmail.com', 'Chulumanda Habeenzu|chulumanda@gmail.com'],
  'Decor & flowers': ['Chibiya Chomba|chibiya@gmail.com', 'Milambo Chishala|milambo@gmail.com', 'Namuchana Chisenga|namuchana@gmail.com', 'Kabwe Kayula|kabwe@gmail.com', 'Mundia Chishiba|mundia@gmail.com', 'Kombe Chansa|kombe@gmail.com', 'Muleya Ndhlovu|muleya@gmail.com', 'Njekwa Mwansa|njekwa@gmail.com', 'Chilombo Chola|chilombo@gmail.com', 'Bwembya Zimba|bwembya@gmail.com'],
  'DJ & MC': ['Kondwani Mwewa|kondwani@gmail.com', 'Emmanuel Sinkala|emmanuel@gmail.com', 'Given Musukwa|given@gmail.com', 'Blessings Chibuye|blessings@gmail.com', 'Ackim Kalenga|ackim@gmail.com', 'Isaac Mwanza|isaac@gmail.com', 'Obrien Nyendwa|obrien@gmail.com', 'Petronella Silwamba|petronella@gmail.com', 'Beatrice Chota|beatrice@gmail.com', 'Danny Daka|danny@gmail.com'],
  Transport: ['Justin Nkonde|justin@gmail.com', 'Boniface Mulele|boniface@gmail.com', 'Christopher Njobvu|christopher@gmail.com', 'Prisca Sitali|prisca@gmail.com', 'Gift Miti|gift@gmail.com', 'Memory Kanyanta|memory@gmail.com', 'Loveness Muyunda|loveness@gmail.com', 'Kelvin Siame|kelvin@gmail.com', 'Mapalo Nchito|mapalo@gmail.com', 'Grace Zulu|grace@gmail.com'],
  'Wedding attire': ['Miyoba Phiri|miyoba@gmail.com', 'Chrispin Tembo|chrispin@gmail.com', 'Chishimba Banda|chishimba@gmail.com', 'Fredrick Mumba|fredrick@gmail.com', 'Precious Sakala|precious@gmail.com', 'Sydney Daka|sydney@gmail.com', 'Habeenzu Ngoma|habeenzu@gmail.com', 'Musunga Lungu|musunga@gmail.com', 'Situmbeko Chulu|situmbeko@gmail.com', 'Mutinta Malama|mutinta@gmail.com'],
  'Cake & sweets': ['Inutu Zulu|inutu@gmail.com', 'Malama Phiri|malama@gmail.com', 'Bupe Tembo|bupe@gmail.com', 'Chilufya Banda|chilufya@gmail.com', 'Simfukwe Mumba|simfukwe@gmail.com', 'Mubanga Sakala|mubanga@gmail.com', 'Chisenga Kunda|chisenga@gmail.com', 'Chishala Mwape|chishala@gmail.com', 'Kayula Kangwa|kayula@gmail.com', 'Chansa Ngoma|chansa@gmail.com'],
};

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

async function setLocation(category, rank, name, email) {
  const city = rank % 2 === 1 ? 'Kitwe' : 'Ndola';
  const { latitude, longitude } = CITIES[city];

  const loginRes = await api('/api/auth/login', { method: 'POST', body: { email, password: PASSWORD } });
  if (!loginRes.ok) {
    console.error(`  SKIP ${name}: login failed — ${JSON.stringify(loginRes.data)}`);
    return;
  }
  const token = loginRes.data.accessToken;

  const putRes = await api('/api/vendors/me', {
    method: 'PUT',
    token,
    body: { business_name: name, category, location: city, latitude, longitude },
  });
  console.log(putRes.ok
    ? `  OK ${name} (${category}) — ${city}`
    : `  FAILED ${name} — ${JSON.stringify(putRes.data)}`);
}

async function main() {
  const health = await fetch(`${API_BASE}/health`).catch(() => null);
  if (!health || !health.ok) {
    console.error(`Backend not reachable at ${API_BASE} — start it first (node server.js).`);
    process.exit(1);
  }

  for (const [category, vendors] of Object.entries(CATEGORIES)) {
    console.log(`\n${category}:`);
    for (let i = 0; i < vendors.length; i++) {
      const [name, email] = vendors[i].split('|');
      if (email === 'kabaso@gmail.com') {
        console.log(`  SKIP ${name}: account still not reachable with shared password.`);
        continue;
      }
      await setLocation(category, i + 1, name, email);
    }
  }

  console.log('\nDone.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Update failed:', err.message);
  process.exit(1);
});

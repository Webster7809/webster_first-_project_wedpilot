// Follow-up to addPdfVendorsViaApi.js — still goes through the real public
// HTTP API (login + PUT/DELETE /api/vendors/me/services/:id), not direct DB
// writes. Two things, per vendor:
//
// 1. Gives each of the 10 vendors in a category a distinct price range. The
//    source PDF only gave one flat starting price per category, so this
//    applies an explicit synthetic spread by rank (vendor #1 cheapest, #10
//    priciest) rather than pretending these are real individually-set
//    prices — the user asked for the variation, knowing the source has none.
// 2. Cleans up the 14 vendors (all Venue + 5 Catering) that already existed
//    before addPdfVendorsViaApi.js ran: each now has two service listings
//    (the user's original manual entry + the one that script added). This
//    deletes the original and keeps the one this import created, identified
//    by its title convention ("<category> package").
//
// kabaso@gmail.com is skipped — its account still isn't reachable with the
// shared password, same as during the original import.
//
// Requires the backend server to already be running. Usage:
// node scripts/updatePdfVendorListingsViaApi.js
require('dotenv').config();

const API_BASE = process.env.API_BASE || 'http://localhost:3000';
const PASSWORD = '12345678';

const CATEGORIES = {
  Venue: { price: 8250, vendors: [
    ['Mwansa Zulu', 'mwansa@gmail.com'], ['Bwalya Phiri', 'bwalya@gmail.com'],
    ['Chileshe Tembo', 'chileshe@gmail.com'], ['Mulenga Banda', 'mulenga@gmail.com'],
    ['Chanda Mumba', 'chanda@gmail.com'], ['Kaluba Sakala', 'kaluba@gmail.com'],
    ['Nkole Daka', 'nkole@gmail.com'], ['Musonda Kunda', 'musonda@gmail.com'],
    ['Chungu Mwape', 'chungu@gmail.com'], ['Chipego Kangwa', 'chipego@gmail.com'],
  ]},
  Catering: { price: 6250, vendors: [
    ['Namwinga Ngoma', 'namwinga@gmail.com'], ['Nchimunya Lungu', 'nchimunya@gmail.com'],
    ['Kabaso Chulu', 'kabaso@gmail.com'], ['Chibale Malama', 'chibale@gmail.com'],
    ['Yamikani Simfukwe', 'yamikani@gmail.com'], ['Katongo Mutinta', 'katongo@gmail.com'],
    ['Sepiso Inutu', 'sepiso@gmail.com'], ['Namakau Mapalo', 'namakau@gmail.com'],
    ['Twaambo Mwaba', 'twaambo@gmail.com'], ['Chola Mutale', 'chola@gmail.com'],
  ]},
  Photography: { price: 2500, vendors: [
    ['Nawa Chisha', 'nawa@gmail.com'], ['Kaonga Lubinda', 'kaonga@gmail.com'],
    ['Chibwe Chitalu', 'chibwe@gmail.com'], ['Mwenya Situmbeko', 'mwenya@gmail.com'],
    ['Kalima Chishimba', 'kalima@gmail.com'], ['Ngandu Musunga', 'ngandu@gmail.com'],
    ['Kalaba Mubanga', 'kalaba@gmail.com'], ['Chikwanda Musanje', 'chikwanda@gmail.com'],
    ['Nsofu Kaseba', 'nsofu@gmail.com'], ['Chulumanda Habeenzu', 'chulumanda@gmail.com'],
  ]},
  'Decor & flowers': { price: 3500, vendors: [
    ['Chibiya Chomba', 'chibiya@gmail.com'], ['Milambo Chishala', 'milambo@gmail.com'],
    ['Namuchana Chisenga', 'namuchana@gmail.com'], ['Kabwe Kayula', 'kabwe@gmail.com'],
    ['Mundia Chishiba', 'mundia@gmail.com'], ['Kombe Chansa', 'kombe@gmail.com'],
    ['Muleya Ndhlovu', 'muleya@gmail.com'], ['Njekwa Mwansa', 'njekwa@gmail.com'],
    ['Chilombo Chola', 'chilombo@gmail.com'], ['Bwembya Zimba', 'bwembya@gmail.com'],
  ]},
  'DJ & MC': { price: 1250, vendors: [
    ['Kondwani Mwewa', 'kondwani@gmail.com'], ['Emmanuel Sinkala', 'emmanuel@gmail.com'],
    ['Given Musukwa', 'given@gmail.com'], ['Blessings Chibuye', 'blessings@gmail.com'],
    ['Ackim Kalenga', 'ackim@gmail.com'], ['Isaac Mwanza', 'isaac@gmail.com'],
    ['Obrien Nyendwa', 'obrien@gmail.com'], ['Petronella Silwamba', 'petronella@gmail.com'],
    ['Beatrice Chota', 'beatrice@gmail.com'], ['Danny Daka', 'danny@gmail.com'],
  ]},
  Transport: { price: 750, vendors: [
    ['Justin Nkonde', 'justin@gmail.com'], ['Boniface Mulele', 'boniface@gmail.com'],
    ['Christopher Njobvu', 'christopher@gmail.com'], ['Prisca Sitali', 'prisca@gmail.com'],
    ['Gift Miti', 'gift@gmail.com'], ['Memory Kanyanta', 'memory@gmail.com'],
    ['Loveness Muyunda', 'loveness@gmail.com'], ['Kelvin Siame', 'kelvin@gmail.com'],
    ['Mapalo Nchito', 'mapalo@gmail.com'], ['Grace Zulu', 'grace@gmail.com'],
  ]},
  'Wedding attire': { price: 1500, vendors: [
    ['Miyoba Phiri', 'miyoba@gmail.com'], ['Chrispin Tembo', 'chrispin@gmail.com'],
    ['Chishimba Banda', 'chishimba@gmail.com'], ['Fredrick Mumba', 'fredrick@gmail.com'],
    ['Precious Sakala', 'precious@gmail.com'], ['Sydney Daka', 'sydney@gmail.com'],
    ['Habeenzu Ngoma', 'habeenzu@gmail.com'], ['Musunga Lungu', 'musunga@gmail.com'],
    ['Situmbeko Chulu', 'situmbeko@gmail.com'], ['Mutinta Malama', 'mutinta@gmail.com'],
  ]},
  'Cake & sweets': { price: 1000, vendors: [
    ['Inutu Zulu', 'inutu@gmail.com'], ['Malama Phiri', 'malama@gmail.com'],
    ['Bupe Tembo', 'bupe@gmail.com'], ['Chilufya Banda', 'chilufya@gmail.com'],
    ['Simfukwe Mumba', 'simfukwe@gmail.com'], ['Mubanga Sakala', 'mubanga@gmail.com'],
    ['Chisenga Kunda', 'chisenga@gmail.com'], ['Chishala Mwape', 'chishala@gmail.com'],
    ['Kayula Kangwa', 'kayula@gmail.com'], ['Chansa Ngoma', 'chansa@gmail.com'],
  ]},
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

function gradientPrice(basePrice, rank) {
  const multiplier = 0.6 + (rank - 1) * 0.1; // rank 1 -> 0.6x, rank 10 -> 1.5x
  const price_min = Math.round(basePrice * multiplier);
  const price_max = Math.round(price_min * 1.15);
  return { price_min, price_max };
}

async function updateVendor(category, basePrice, rank, [name, email]) {
  const loginRes = await api('/api/auth/login', { method: 'POST', body: { email, password: PASSWORD } });
  if (!loginRes.ok) {
    console.error(`  SKIP ${name}: login failed — ${JSON.stringify(loginRes.data)}`);
    return;
  }
  const token = loginRes.data.accessToken;

  const meRes = await api('/api/vendors/me', { token });
  if (!meRes.ok) {
    console.error(`  SKIP ${name}: could not load profile — ${JSON.stringify(meRes.data)}`);
    return;
  }
  const services = meRes.data.vendor?.services ?? [];
  const mine = services.find((s) => s.title === `${category} package`);
  const originals = services.filter((s) => s.title !== `${category} package`);

  for (const orig of originals) {
    const del = await api(`/api/vendors/me/services/${orig.service_id}`, { method: 'DELETE', token });
    console.log(del.ok
      ? `  Deleted duplicate listing "${orig.title}" for ${name}`
      : `  FAILED to delete "${orig.title}" for ${name} — ${JSON.stringify(del.data)}`);
  }

  if (!mine) {
    console.error(`  SKIP ${name}: no "${category} package" listing found to price.`);
    return;
  }
  const { price_min, price_max } = gradientPrice(basePrice, rank);
  const upd = await api(`/api/vendors/me/services/${mine.service_id}`, {
    method: 'PUT',
    token,
    body: { price_min, price_max },
  });
  console.log(upd.ok
    ? `  OK ${name} (${category}) — ZMW ${price_min}-${price_max}`
    : `  FAILED to price ${name} — ${JSON.stringify(upd.data)}`);
}

async function main() {
  const health = await fetch(`${API_BASE}/health`).catch(() => null);
  if (!health || !health.ok) {
    console.error(`Backend not reachable at ${API_BASE} — start it first (node server.js).`);
    process.exit(1);
  }

  for (const [category, { price, vendors }] of Object.entries(CATEGORIES)) {
    console.log(`\n${category} (base ZMW ${price}):`);
    for (let i = 0; i < vendors.length; i++) {
      const [name, email] = vendors[i];
      if (email === 'kabaso@gmail.com') {
        console.log(`  SKIP ${name}: account still not reachable with shared password.`);
        continue;
      }
      await updateVendor(category, price, i + 1, vendors[i]);
    }
  }

  console.log('\nDone.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Update failed:', err.message);
  process.exit(1);
});

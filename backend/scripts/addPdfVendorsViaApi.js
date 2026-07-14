// One-off import script — adds vendors through the app's real public HTTP
// API (POST /api/auth/register, PUT /api/vendors/me, POST /api/vendors/me/services),
// the exact same endpoints the Flutter frontend calls, instead of writing
// directly to the database like backend/scripts/seedTestVendors.js does. Each
// vendor is created by actually registering an account and submitting the
// same onboarding + listing requests a real vendor's signup would make.
//
// Source data: WedPilot_Vendor_Directory.pdf (name, email, one-line offering
// per vendor, plus a single starting price per category). No location or
// per-vendor pricing was given in that source, so those fields are left
// null/uniform rather than invented — see README notes below.
//
// Requires the backend server to already be running (node server.js) at
// API_BASE. Usage: node scripts/addPdfVendorsViaApi.js
require('dotenv').config();

const API_BASE = process.env.API_BASE || 'http://localhost:3000';
const PASSWORD = '12345678';
const PHONE = '0776595262';

// category -> [starting price ZMW, vendors[]]
const CATEGORIES = {
  Venue: {
    price: 8250,
    vendors: [
      ['Mwansa Zulu', 'mwansa@gmail.com', 'Outdoor garden venue, up to 300 guests, in-house catering'],
      ['Bwalya Phiri', 'bwalya@gmail.com', 'Indoor ballroom, seats 250, chandelier lighting & stage'],
      ['Chileshe Tembo', 'chileshe@gmail.com', 'Riverside lodge grounds, ideal for outdoor ceremonies'],
      ['Mulenga Banda', 'mulenga@gmail.com', 'Hotel hall convertible to reception venue, 200 pax'],
      ['Chanda Mumba', 'chanda@gmail.com', 'Boutique garden estate with gazebo, up to 150 guests'],
      ['Kaluba Sakala', 'kaluba@gmail.com', 'Spacious event centre hall, on-site parking for 100 cars'],
      ['Nkole Daka', 'nkole@gmail.com', 'Poolside venue with terrace seating, up to 180 guests'],
      ['Musonda Kunda', 'musonda@gmail.com', 'Rustic farm & barn venue, countryside setting'],
      ['Chungu Mwape', 'chungu@gmail.com', 'Rooftop venue with city views, up to 120 guests'],
      ['Chipego Kangwa', 'chipego@gmail.com', 'Church hall and grounds, budget-friendly package'],
    ],
  },
  Catering: {
    price: 6250,
    vendors: [
      ['Namwinga Ngoma', 'namwinga@gmail.com', 'Full-course Zambian & continental buffet, up to 300 guests'],
      ['Nchimunya Lungu', 'nchimunya@gmail.com', 'Traditional Zambian cuisine specialist, nshima & relish platters'],
      ['Kabaso Chulu', 'kabaso@gmail.com', 'Plated fine-dining service with waitstaff included'],
      ['Chibale Malama', 'chibale@gmail.com', 'BBQ & braai catering with outdoor grill stations'],
      ['Yamikani Simfukwe', 'yamikani@gmail.com', 'Vegetarian & vegan-friendly wedding menus'],
      ['Katongo Mutinta', 'katongo@gmail.com', 'Budget buffet packages for 100-150 guests'],
      ['Sepiso Inutu', 'sepiso@gmail.com', 'Premium canapes & cocktail-hour catering'],
      ['Namakau Mapalo', 'namakau@gmail.com', 'Multi-cuisine fusion menu, Indian & Zambian options'],
      ['Twaambo Mwaba', 'twaambo@gmail.com', 'Carvery-style station with live cooking'],
      ['Chola Mutale', 'chola@gmail.com', 'Full catering incl. cutlery, crockery & linen hire'],
    ],
  },
  Photography: {
    price: 2500,
    vendors: [
      ['Nawa Chisha', 'nawa@gmail.com', 'Full-day wedding photography, 500+ edited photos'],
      ['Kaonga Lubinda', 'kaonga@gmail.com', 'Photo + videography combo package with drone shots'],
      ['Chibwe Chitalu', 'chibwe@gmail.com', 'Traditional ceremony specialist, documentary style'],
      ['Mwenya Situmbeko', 'mwenya@gmail.com', 'Studio portraits plus outdoor pre-wedding shoots'],
      ['Kalima Chishimba', 'kalima@gmail.com', 'Same-day edit & instant prints for guests'],
      ['Ngandu Musunga', 'ngandu@gmail.com', 'Cinematic wedding films with highlight reel'],
      ['Kalaba Mubanga', 'kalaba@gmail.com', 'Candid & photojournalistic coverage style'],
      ['Chikwanda Musanje', 'chikwanda@gmail.com', 'Drone aerial photography & videography add-on'],
      ['Nsofu Kaseba', 'nsofu@gmail.com', 'Engagement shoot bundled with full wedding day package'],
      ['Chulumanda Habeenzu', 'chulumanda@gmail.com', 'Photo booth rental with props included'],
    ],
  },
  'Decor & flowers': {
    price: 3500,
    vendors: [
      ['Chibiya Chomba', 'chibiya@gmail.com', 'Full venue draping & fairy-light installations'],
      ['Milambo Chishala', 'milambo@gmail.com', 'Fresh floral arrangements & bridal bouquets'],
      ['Namuchana Chisenga', 'namuchana@gmail.com', 'Themed table centrepieces & backdrop design'],
      ['Kabwe Kayula', 'kabwe@gmail.com', 'Balloon arches & event styling'],
      ['Mundia Chishiba', 'mundia@gmail.com', 'Traditional ceremony decor, chitenge-inspired themes'],
      ['Kombe Chansa', 'kombe@gmail.com', 'Outdoor garden decor & arch installations'],
      ['Muleya Ndhlovu', 'muleya@gmail.com', 'Luxury florals, imported & local flower mixes'],
      ['Njekwa Mwansa', 'njekwa@gmail.com', 'Aisle & altar decoration specialists'],
      ['Chilombo Chola', 'chilombo@gmail.com', 'Full event styling incl. lighting & linens'],
      ['Bwembya Zimba', 'bwembya@gmail.com', 'Silk & artificial flower arrangements, budget-friendly'],
    ],
  },
  'DJ & MC': {
    price: 1250,
    vendors: [
      ['Kondwani Mwewa', 'kondwani@gmail.com', 'Full sound system, DJ set & MC hosting combo'],
      ['Emmanuel Sinkala', 'emmanuel@gmail.com', 'Bilingual MC hosting, English & Bemba'],
      ['Given Musukwa', 'given@gmail.com', 'Live band coordination plus DJ transitions'],
      ['Blessings Chibuye', 'blessings@gmail.com', 'Kids-friendly & family reception playlists'],
      ['Ackim Kalenga', 'ackim@gmail.com', 'Traditional & Afrobeat mix specialist'],
      ['Isaac Mwanza', 'isaac@gmail.com', 'Lighting rig, dance floor & DJ package'],
      ['Obrien Nyendwa', 'obrien@gmail.com', 'MC hosting with games & icebreakers'],
      ['Petronella Silwamba', 'petronella@gmail.com', 'Female MC, bilingual English & Nyanja hosting'],
      ['Beatrice Chota', 'beatrice@gmail.com', 'Live saxophonist add-on with DJ set'],
      ['Danny Daka', 'danny@gmail.com', 'Karaoke & open-mic entertainment package'],
    ],
  },
  Transport: {
    price: 750,
    vendors: [
      ['Justin Nkonde', 'justin@gmail.com', 'Luxury sedan hire for bride & groom'],
      ['Boniface Mulele', 'boniface@gmail.com', 'Guest shuttle bus service, up to 40 seats'],
      ['Christopher Njobvu', 'christopher@gmail.com', 'Vintage classic car rental with driver'],
      ['Prisca Sitali', 'prisca@gmail.com', 'Decorated bridal car with ribbons & flowers'],
      ['Gift Miti', 'gift@gmail.com', 'Minivan hire for bridal party transport'],
      ['Memory Kanyanta', 'memory@gmail.com', 'Airport transfers for out-of-town guests'],
      ['Loveness Muyunda', 'loveness@gmail.com', 'Convertible car rental for grand entrances'],
      ['Kelvin Siame', 'kelvin@gmail.com', 'Fleet of SUVs for groomsmen & bridesmaids'],
      ['Mapalo Nchito', 'mapalo@gmail.com', 'Horse-drawn carriage hire for grand entrance'],
      ['Grace Zulu', 'grace@gmail.com', 'Chauffeur-driven limousine hire package'],
    ],
  },
  'Wedding attire': {
    price: 1500,
    vendors: [
      ['Miyoba Phiri', 'miyoba@gmail.com', 'Custom bridal gowns & alterations'],
      ['Chrispin Tembo', 'chrispin@gmail.com', 'Groom & groomsmen suit tailoring'],
      ['Chishimba Banda', 'chishimba@gmail.com', 'Chitenge & traditional wear designer'],
      ['Fredrick Mumba', 'fredrick@gmail.com', 'Wedding gown rental packages'],
      ['Precious Sakala', 'precious@gmail.com', 'Bridesmaid dress design & fittings'],
      ['Sydney Daka', 'sydney@gmail.com', 'Custom tuxedo & suit hire'],
      ['Habeenzu Ngoma', 'habeenzu@gmail.com', 'Bridal accessories, veils & jewellery'],
      ['Musunga Lungu', 'musunga@gmail.com', 'Traditional attire for both families'],
      ['Situmbeko Chulu', 'situmbeko@gmail.com', 'Made-to-measure wedding gowns'],
      ['Mutinta Malama', 'mutinta@gmail.com', 'Flower girl & page boy outfits'],
    ],
  },
  'Cake & sweets': {
    price: 1000,
    vendors: [
      ['Inutu Zulu', 'inutu@gmail.com', 'Multi-tier custom wedding cakes'],
      ['Malama Phiri', 'malama@gmail.com', 'Cupcake towers & dessert tables'],
      ['Bupe Tembo', 'bupe@gmail.com', 'Chocolate fountain & candy bar setup'],
      ['Chilufya Banda', 'chilufya@gmail.com', 'Traditional Zambian sweets & pastries'],
      ['Simfukwe Mumba', 'simfukwe@gmail.com', 'Fondant-decorated themed cakes'],
      ['Mubanga Sakala', 'mubanga@gmail.com', 'Gluten-free & allergen-friendly cake options'],
      ['Chisenga Kunda', 'chisenga@gmail.com', 'Cake tasting sessions & custom flavours'],
      ['Chishala Mwape', 'chishala@gmail.com', 'Mini dessert bites & macarons'],
      ["Kayula Kangwa", 'kayula@gmail.com', "Groom's cake specialist, novelty designs"],
      ['Chansa Ngoma', 'chansa@gmail.com', 'Cake delivery & on-site setup service'],
    ],
  },
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
  const data = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data };
}

async function addVendor(category, price, [name, email, offering]) {
  // Register — if the account already exists (re-running the script), log
  // in instead so the script is safe to re-run without duplicating listings.
  let token;
  const registerRes = await api('/api/auth/register', {
    method: 'POST',
    body: { email, password: PASSWORD, name, role: 'vendor' },
  });
  if (registerRes.ok) {
    token = registerRes.data.accessToken;
  } else if (registerRes.status === 409) {
    const loginRes = await api('/api/auth/login', {
      method: 'POST',
      body: { email, password: PASSWORD },
    });
    if (!loginRes.ok) {
      console.error(`  SKIP ${name}: account exists but login failed — ${JSON.stringify(loginRes.data)}`);
      return false;
    }
    token = loginRes.data.accessToken;
  } else {
    console.error(`  FAIL ${name}: register failed — ${JSON.stringify(registerRes.data)}`);
    return false;
  }

  const profileRes = await api('/api/vendors/me', {
    method: 'PUT',
    token,
    body: {
      business_name: name,
      description: offering,
      category,
      phone: PHONE,
      contact_email: email,
    },
  });
  if (!profileRes.ok) {
    console.error(`  FAIL ${name}: profile save failed — ${JSON.stringify(profileRes.data)}`);
    return false;
  }

  const serviceRes = await api('/api/vendors/me/services', {
    method: 'POST',
    token,
    body: {
      title: `${category} package`,
      description: offering,
      // The source PDF gives one starting price per category, not a
      // per-vendor range — using it as both ends rather than inventing a
      // spread that was never given.
      price_min: price,
      price_max: price,
      unit: 'package',
    },
  });
  if (!serviceRes.ok) {
    console.error(`  FAIL ${name}: service listing failed — ${JSON.stringify(serviceRes.data)}`);
    return false;
  }

  console.log(`  OK ${name} (${category}) — ${email}`);
  return true;
}

async function main() {
  const health = await fetch(`${API_BASE}/health`).catch(() => null);
  if (!health || !health.ok) {
    console.error(`Backend not reachable at ${API_BASE} — start it first (node server.js).`);
    process.exit(1);
  }

  let succeeded = 0;
  let failed = 0;
  for (const [category, { price, vendors }] of Object.entries(CATEGORIES)) {
    console.log(`\n${category} (ZMW ${price}):`);
    for (const v of vendors) {
      const ok = await addVendor(category, price, v);
      if (ok) succeeded++;
      else failed++;
    }
  }

  console.log(`\nDone. ${succeeded} vendor(s) added, ${failed} failed.`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('Import failed:', err.message);
  process.exit(1);
});

// DEV-ONLY — NEVER RUN AGAINST A PRODUCTION DB_NAME.
// Creates 12 fictional vendors (`.test` email domains) per category — one
// for each combination of {Lusaka, Kitwe, Ndola, Chipata} x {low, flexible,
// high} budget tier — so location- and budget-based matching can be
// exercised with even coverage across all four cities and all three price
// bands, in every category. Complements seedTestVendors.js, which already
// covers Lusaka/Ndola/Kitwe with a mix of reputations; this script adds
// Chipata and guarantees a clean 4x3 spread per category.
// Usage: node scripts/seedZambianVendors.js
require('dotenv').config();
const bcrypt = require('bcrypt');
const sequelize = require('../db/sequelize');
const User = require('../db/models/user');
const Vendor = require('../db/models/vendor');
const { setVendorStyleTags } = require('../services/styleTags');
const VendorService = require('../db/models/vendorService');
const VendorMedia = require('../db/models/vendorMedia');

const TEST_PASSWORD = 'VendorTest123!';

const LOCATIONS = {
  Lusaka: { latitude: -15.4167, longitude: 28.2833 },
  Kitwe: { latitude: -12.8024, longitude: 28.2132 },
  Ndola: { latitude: -12.9587, longitude: 28.6366 },
  Chipata: { latitude: -13.6333, longitude: 32.65 },
};

const TIERS = ['low', 'flexible', 'high'];
const STYLE_BY_TIER = {
  low: ['Traditional', 'Rustic'],
  flexible: ['Modern', 'Bohemian'],
  high: ['Elegant', 'Modern'],
};

// [min, max] ZMW per tier, before the small per-city jitter applied below.
const PRICE_BANDS = {
  Venue: { low: [5000, 12000], flexible: [15000, 32000], high: [40000, 90000] },
  Catering: { low: [3000, 7000], flexible: [8000, 18000], high: [20000, 38000] },
  Photography: { low: [1500, 4000], flexible: [5000, 9500], high: [10000, 20000] },
  'Decor & flowers': { low: [1500, 4000], flexible: [5000, 10000], high: [12000, 24000] },
  'DJ & MC': { low: [1200, 3000], flexible: [3500, 7000], high: [8000, 15000] },
  Transport: { low: [700, 2000], flexible: [2500, 5500], high: [6000, 13000] },
  'Wedding attire': { low: [900, 2800], flexible: [3000, 8000], high: [9000, 22000] },
  'Cake & sweets': { low: [600, 1600], flexible: [1800, 3800], high: [4000, 9000] },
};

const MAX_GUESTS = {
  Venue: { low: 100, flexible: 250, high: 500 },
  Catering: { low: 100, flexible: 250, high: 450 },
  Photography: { low: 60, flexible: 150, high: 300 },
  'Decor & flowers': { low: 80, flexible: 200, high: 400 },
  'DJ & MC': { low: 80, flexible: 200, high: 400 },
  Transport: { low: 50, flexible: 120, high: 250 },
  'Wedding attire': { low: 50, flexible: 120, high: 250 },
  'Cake & sweets': { low: 50, flexible: 120, high: 300 },
};

const UNIT_BY_CATEGORY = {
  Venue: 'package',
  Catering: 'per event',
  Photography: 'package',
  'Decor & flowers': 'package',
  'DJ & MC': 'package',
  Transport: 'per event',
  'Wedding attire': 'package',
  'Cake & sweets': 'package',
};

const DESCRIPTION_TEMPLATES = {
  Venue: {
    low: 'Simple, budget-friendly venue for an intimate wedding celebration in {location}.',
    flexible: 'Versatile mid-range venue with flexible packages for weddings in {location}.',
    high: 'Premium, full-service wedding venue offering a luxury experience in {location}.',
  },
  Catering: {
    low: 'Affordable home-style Zambian catering for weddings in {location}.',
    flexible: 'Flexible catering packages with a varied menu, based in {location}.',
    high: 'Premium plated catering with a customisable fine-dining menu in {location}.',
  },
  Photography: {
    low: 'Budget-friendly wedding photography with a digital gallery, based in {location}.',
    flexible: 'Full-day wedding photography coverage with flexible packages in {location}.',
    high: 'Premium wedding photography with a second shooter and printed album, {location}.',
  },
  'Decor & flowers': {
    low: 'Simple, affordable floral arrangements and decor for weddings in {location}.',
    flexible: 'Flexible décor and floral styling packages based in {location}.',
    high: 'Premium event styling and full venue floral transformation in {location}.',
  },
  'DJ & MC': {
    low: 'Affordable DJ and sound hire for wedding receptions in {location}.',
    flexible: 'Flexible DJ and MC packages with a mix of playlists, based in {location}.',
    high: 'Premium DJ, MC and lighting production for large receptions in {location}.',
  },
  Transport: {
    low: 'Affordable guest shuttle and bridal car hire in {location}.',
    flexible: 'Flexible wedding car hire packages based in {location}.',
    high: 'Premium chauffeured luxury car hire for the wedding party in {location}.',
  },
  'Wedding attire': {
    low: 'Budget bridal and groom attire rentals in {location}.',
    flexible: 'Flexible bridal wear and suiting at mid-range prices, {location}.',
    high: 'Designer bridal gowns and tailored suits, made-to-measure, {location}.',
  },
  'Cake & sweets': {
    low: 'Affordable wedding cakes and sweets platters in {location}.',
    flexible: 'Flexible custom cake packages and dessert tables, {location}.',
    high: 'Premium custom multi-tier wedding cakes with elegant designs, {location}.',
  },
};

// 12 (business name, location, tier) entries per category — one per
// {city} x {tier} combination, using Zambian surnames common across
// Lusaka/Copperbelt/Eastern Province.
const CATEGORY_ENTRIES = {
  Venue: [
    ['Mwansa Gardens', 'Lusaka', 'low'],
    ['Zulu Manor Grounds', 'Lusaka', 'flexible'],
    ['Mubanga Royal Estate', 'Lusaka', 'high'],
    ['Chileshe Garden Hall', 'Kitwe', 'low'],
    ['Bwalya Grounds & Gardens', 'Kitwe', 'flexible'],
    ['Kunda Palace Estate', 'Kitwe', 'high'],
    ['Sakala Hall', 'Ndola', 'low'],
    ['Mulenga Lodge Grounds', 'Ndola', 'flexible'],
    ['Chirwa Heritage Estate', 'Ndola', 'high'],
    ['Banda Community Hall', 'Chipata', 'low'],
    ['Phiri Garden Grounds', 'Chipata', 'flexible'],
    ['Tembo Manor Estate', 'Chipata', 'high'],
  ],
  Catering: [
    ["Mumba's Kitchen Catering", 'Lusaka', 'low'],
    ['Chanda Feast Catering', 'Lusaka', 'flexible'],
    ['Nkonde Fine Catering', 'Lusaka', 'high'],
    ['Bwalya Home Table Catering', 'Kitwe', 'low'],
    ['Chileshe Chefs Catering', 'Kitwe', 'flexible'],
    ['Mulenga Signature Cuisine', 'Kitwe', 'high'],
    ["Sakala's Table Catering", 'Ndola', 'low'],
    ['Musonda Feast Catering', 'Ndola', 'flexible'],
    ['Zulu Elegant Catering', 'Ndola', 'high'],
    ["Banda's Kitchen Catering", 'Chipata', 'low'],
    ['Phiri Home Catering', 'Chipata', 'flexible'],
    ['Tembo Fine Dining Catering', 'Chipata', 'high'],
  ],
  Photography: [
    ['Chanda Lens Studio', 'Lusaka', 'low'],
    ['Mwape Shutter Studios', 'Lusaka', 'flexible'],
    ['Kaluba Signature Photography', 'Lusaka', 'high'],
    ['Kunda Frame Works', 'Kitwe', 'low'],
    ['Chibale Captures Studio', 'Kitwe', 'flexible'],
    ['Mubanga Elite Photography', 'Kitwe', 'high'],
    ['Nkonde Lens & Light', 'Ndola', 'low'],
    ['Musonda Moments Photography', 'Ndola', 'flexible'],
    ['Sinkala Premier Photography', 'Ndola', 'high'],
    ['Zimba Frame Studio', 'Chipata', 'low'],
    ['Daka Captures Photography', 'Chipata', 'flexible'],
    ['Nyirenda Grand Photography', 'Chipata', 'high'],
  ],
  'Decor & flowers': [
    ['Mumba Petals Decor', 'Lusaka', 'low'],
    ['Sakala Floral Designs', 'Lusaka', 'flexible'],
    ['Kabwe Elegant Blooms', 'Lusaka', 'high'],
    ['Chileshe Blooms & Decor', 'Kitwe', 'low'],
    ['Bwalya Floral Studio', 'Kitwe', 'flexible'],
    ['Mulenga Signature Décor', 'Kitwe', 'high'],
    ['Musonda Petals & Design', 'Ndola', 'low'],
    ['Sinkala Floral House', 'Ndola', 'flexible'],
    ['Zulu Grand Decor Studio', 'Ndola', 'high'],
    ['Banda Garden Blooms', 'Chipata', 'low'],
    ['Phiri Floral Designs', 'Chipata', 'flexible'],
    ['Tembo Elite Decor', 'Chipata', 'high'],
  ],
  'DJ & MC': [
    ['DJ Mwansa Sound', 'Lusaka', 'low'],
    ['MC Chanda Live Entertainment', 'Lusaka', 'flexible'],
    ['Prime Kunda Entertainment', 'Lusaka', 'high'],
    ['Copperbelt Bwalya Beats', 'Kitwe', 'low'],
    ['DJ Chileshe Sound Crew', 'Kitwe', 'flexible'],
    ['Mulenga Grand Entertainment', 'Kitwe', 'high'],
    ['MC Sakala Live', 'Ndola', 'low'],
    ['DJ Musonda Sound & Lights', 'Ndola', 'flexible'],
    ['Zulu Premier Entertainment', 'Ndola', 'high'],
    ['DJ Banda Sound', 'Chipata', 'low'],
    ['MC Phiri Live Entertainment', 'Chipata', 'flexible'],
    ['Tembo Grand Sound & MC', 'Chipata', 'high'],
  ],
  Transport: [
    ['Mwansa Budget Rides', 'Lusaka', 'low'],
    ['Chanda Wedding Cars', 'Lusaka', 'flexible'],
    ['Kunda Royal Chauffeurs', 'Lusaka', 'high'],
    ['Bwalya Shuttle Services', 'Kitwe', 'low'],
    ['Chileshe Classic Cars', 'Kitwe', 'flexible'],
    ['Mulenga Prestige Rides', 'Kitwe', 'high'],
    ['Sakala Guest Shuttle', 'Ndola', 'low'],
    ['Musonda Wedding Cars', 'Ndola', 'flexible'],
    ['Zulu Royal Transport', 'Ndola', 'high'],
    ['Banda Budget Transport', 'Chipata', 'low'],
    ['Phiri Wedding Rides', 'Chipata', 'flexible'],
    ['Tembo Prestige Transport', 'Chipata', 'high'],
  ],
  'Wedding attire': [
    ['Mumba Bridal Boutique', 'Lusaka', 'low'],
    ['Sakala Chic Bridal', 'Lusaka', 'flexible'],
    ['Kabwe Designer Bridal House', 'Lusaka', 'high'],
    ['Chileshe Tailors & Bridal', 'Kitwe', 'low'],
    ['Bwalya Fashion House', 'Kitwe', 'flexible'],
    ['Mulenga Couture Bridal', 'Kitwe', 'high'],
    ['Musonda Bridal Rentals', 'Ndola', 'low'],
    ['Sinkala Bridal Boutique', 'Ndola', 'flexible'],
    ['Zulu Elegance Bridal House', 'Ndola', 'high'],
    ['Banda Tailors & Bridal', 'Chipata', 'low'],
    ['Phiri Bridal Fashion', 'Chipata', 'flexible'],
    ['Tembo Couture Bridal House', 'Chipata', 'high'],
  ],
  'Cake & sweets': [
    ['Mumba Sweet Bakery', 'Lusaka', 'low'],
    ['Sakala Cake Studio', 'Lusaka', 'flexible'],
    ['Kabwe Signature Cakes', 'Lusaka', 'high'],
    ['Chileshe Sweet Treats', 'Kitwe', 'low'],
    ['Bwalya Cake Studio', 'Kitwe', 'flexible'],
    ['Mulenga Divine Cakes', 'Kitwe', 'high'],
    ['Musonda Delight Bakery', 'Ndola', 'low'],
    ['Sinkala Cake House', 'Ndola', 'flexible'],
    ['Zulu Signature Confections', 'Ndola', 'high'],
    ['Banda Sweet Bakery', 'Chipata', 'low'],
    ['Phiri Cake Studio', 'Chipata', 'flexible'],
    ['Tembo Elegant Cakes', 'Chipata', 'high'],
  ],
};

function slugify(name) {
  return name
    .toLowerCase()
    .replace(/&/g, 'and')
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '');
}

// Small deterministic jitter per city (0..3) so same-tier vendors across the
// four cities don't all land on the exact same price, without needing
// randomness (keeps the script's output stable across re-runs).
function jitter([min, max], cityIndex) {
  const factor = 0.94 + cityIndex * 0.04; // 0.94, 0.98, 1.02, 1.06
  const round50 = (n) => Math.round(n / 50) * 50;
  return [round50(min * factor), round50(max * factor)];
}

function buildVendors() {
  const cityOrder = Object.keys(LOCATIONS);
  const vendors = [];
  for (const [category, entries] of Object.entries(CATEGORY_ENTRIES)) {
    for (const [name, location, tier] of entries) {
      const cityIndex = cityOrder.indexOf(location);
      const [price_min, price_max] = jitter(PRICE_BANDS[category][tier], cityIndex);
      vendors.push({
        email: `hello@${slugify(name)}.test`,
        business_name: name,
        category,
        description: DESCRIPTION_TEMPLATES[category][tier].replace('{location}', location),
        style_tags: STYLE_BY_TIER[tier],
        location,
        latitude: LOCATIONS[location].latitude,
        longitude: LOCATIONS[location].longitude,
        price_min,
        price_max,
        unit: UNIT_BY_CATEGORY[category],
        max_guests: MAX_GUESTS[category][tier],
        tier,
      });
    }
  }
  return vendors;
}

async function main() {
  await sequelize.authenticate();
  const password_hash = await bcrypt.hash(TEST_PASSWORD, 10);
  const vendors = buildVendors();

  let created = 0;
  let skipped = 0;

  for (const v of vendors) {
    const existingUser = await User.findOne({ where: { email: v.email } });
    if (existingUser) {
      console.log(`Skipping ${v.business_name} — ${v.email} already exists.`);
      skipped++;
      continue;
    }

    const user = await User.create({
      email: v.email,
      password_hash,
      name: v.business_name,
      role: 'vendor',
      is_verified: true,
    });

    const vendor = await Vendor.create({
      user_id: user.user_id,
      business_name: v.business_name,
      description: v.description,
      category: v.category,
      location: v.location,
      latitude: v.latitude,
      longitude: v.longitude,
      tier: 'free',
      verification_status: 'verified',
    });
    await setVendorStyleTags(vendor.vendor_id, v.style_tags);

    await VendorService.create({
      vendor_id: vendor.vendor_id,
      title: `${v.category} package`,
      description: v.description,
      price_min: v.price_min,
      price_max: v.price_max,
      unit: v.unit,
      max_guests: v.max_guests,
    });

    // Lorem Picsum: real curated photography, no API key, and a seeded URL
    // is permanent — the same seed always returns the same image, so a
    // per-vendor slug guarantees no two vendors ever share a photo.
    const photoSlug = slugify(v.business_name);
    for (let i = 0; i < 3; i++) {
      await VendorMedia.create({
        vendor_id: vendor.vendor_id,
        type: 'image',
        url: `https://picsum.photos/seed/${photoSlug}-${i}/1200/800`,
        thumbnail_url: `https://picsum.photos/seed/${photoSlug}-${i}/400/300`,
        sort_order: i,
        is_featured: i === 0,
      });
    }

    console.log(
      `Created ${v.business_name} (${v.category}, ${v.location}, ${v.tier} budget, `
      + `${v.price_min}-${v.price_max} ZMW) — login: ${v.email} / ${TEST_PASSWORD}`,
    );
    created++;
  }

  console.log(`\nDone. Created ${created}, skipped ${skipped} (already existed).`);
  process.exit(0);
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Failed to seed Zambian vendors:', err.message);
    process.exit(1);
  });
}

module.exports = { buildVendors };

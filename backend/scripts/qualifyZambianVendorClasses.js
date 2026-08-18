// DEV-ONLY — NEVER RUN AGAINST A PRODUCTION DB_NAME.
// Gives the 96 vendors from seedZambianVendors.js exactly what they need to
// earn the wedding class matching their name's budget tier, per the criteria
// in lib/core/services/vendor_class_service.dart:
//
//   low      -> stays Budget-Friendly (the default — no packages, no reviews)
//   flexible -> earns Flexible: verified (already true) + rating >= 3.5 +
//               >= 3 reviews + at least one registered package
//   high     -> earns High Class: verified + rating >= 4.5 + >= 10 reviews +
//               >= 90% recommend rate + a luxury package with 3+ inclusions
//
// Idempotent: setPackages() replaces a vendor's package list rather than
// appending, and feedback is skipped per (couple, vendor) pair that already
// has it — safe to re-run.
// Usage: node scripts/qualifyZambianVendorClasses.js
require('dotenv').config();
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const sequelize = require('../db/sequelize');
const User = require('../db/models/user');
const Vendor = require('../db/models/vendor');
const Inquiry = require('../db/models/inquiry');
const VendorFeedback = require('../db/models/vendorFeedback');
const { setPackages } = require('../services/vendorPackages');
const { recalculateVendorStats } = require('../services/vendorStats');
const { buildVendors } = require('./seedZambianVendors');

const SEED_COUPLE_COUNT = 10; // >= highClassMinReviews so every high-tier vendor gets a distinct couple per review
const SEED_PASSWORD = 'SeedCouple123!';

const STARTER_INCLUSIONS = {
  Venue: ['Venue hire for up to 6 hours', 'Basic table and chair setup'],
  Catering: ['Buffet-style service', 'Standard menu for up to 100 guests'],
  Photography: ['4 hours of coverage', 'Digital gallery of edited photos'],
  'Decor & flowers': ['Table centrepieces', 'Basic venue styling'],
  'DJ & MC': ['4 hours of DJ service', 'Basic sound system'],
  Transport: ['One bridal car', 'Driver for the day'],
  'Wedding attire': ['One outfit fitting', 'Basic alterations'],
  'Cake & sweets': ['Single-tier cake', 'Standard flavour selection'],
};

const LUXURY_INCLUSIONS = {
  Venue: ['Full-day venue hire', 'In-house event coordinator', 'Premium furniture and lighting', 'Bridal suite access'],
  Catering: ['Plated multi-course service', 'Custom menu tasting session', 'Dedicated waitstaff', 'Premium bar package'],
  Photography: ['Full-day coverage with second shooter', 'Printed premium album', 'Engagement shoot included', 'Same-week digital gallery'],
  'Decor & flowers': ['Full venue floral transformation', 'Bridal bouquet and boutonnières', 'Ceremony arch styling', 'On-site styling team'],
  'DJ & MC': ['Full reception DJ and MC', 'Premium lighting production', 'Wireless microphones', 'Custom playlist consultation'],
  Transport: ['Luxury chauffeured car fleet', 'Red carpet service', 'Complimentary guest shuttle', 'Decorated bridal car'],
  'Wedding attire': ['Made-to-measure gown or suit', 'Multiple fittings included', 'Complimentary alterations', 'Accessories styling session'],
  'Cake & sweets': ['Multi-tier custom design', 'Tasting session with 4 flavours', 'Dessert table add-on', 'Delivery and setup included'],
};

async function ensureSeedCouples(password_hash) {
  const couples = [];
  for (let i = 1; i <= SEED_COUPLE_COUNT; i++) {
    const email = `zambian-seed-couple-${String(i).padStart(2, '0')}@test.com`;
    let user = await User.findOne({ where: { email } });
    if (!user) {
      user = await User.create({
        email,
        password_hash,
        name: `Seed Couple ${i}`,
        role: 'couple',
        is_verified: true,
      });
    }
    couples.push(user);
  }
  return couples;
}

async function ensureFeedback(vendor, couples, ratings) {
  let created = 0;
  for (let i = 0; i < ratings.length; i++) {
    const couple = couples[i];
    const existing = await VendorFeedback.findOne({
      where: { couple_user_id: couple.user_id, vendor_id: vendor.vendor_id },
    });
    if (existing) continue;

    const now = new Date();
    const inquiry = await Inquiry.create({
      couple_user_id: couple.user_id,
      vendor_id: vendor.vendor_id,
      message: `Hi! We'd love to book you for our wedding.`,
      status: 'booked',
      responded_at: now,
      service_done_at: now,
      rating_reminder_count: 1,
      rating_reminder_last_sent_at: now,
    });

    await VendorFeedback.create({
      couple_user_id: couple.user_id,
      vendor_id: vendor.vendor_id,
      inquiry_id: inquiry.inquiry_id,
      star_rating: ratings[i],
      comment: 'Great to work with, highly recommend!',
      on_time: 'yes',
    });
    created++;
  }
  return created;
}

async function main() {
  await sequelize.authenticate();
  const password_hash = await bcrypt.hash(SEED_PASSWORD, 10);
  const couples = await ensureSeedCouples(password_hash);

  const vendors = buildVendors();
  let flexibleCount = 0;
  let highCount = 0;
  let missing = 0;

  for (const v of vendors) {
    if (v.tier === 'low') continue; // stays Budget-Friendly by design

    const user = await User.findOne({ where: { email: v.email } });
    if (!user) {
      console.log(`Missing vendor for ${v.email} — run seedZambianVendors.js first.`);
      missing++;
      continue;
    }
    const vendor = await Vendor.findOne({ where: { user_id: user.user_id } });
    if (!vendor) {
      missing++;
      continue;
    }

    if (v.tier === 'flexible') {
      await setPackages(vendor.vendor_id, [{
        package_id: crypto.randomUUID(),
        tier: 'starter',
        title: `${v.category} Starter Package`,
        price: v.price_min,
        inclusions: STARTER_INCLUSIONS[v.category],
      }]);
      const created = await ensureFeedback(vendor, couples, [5, 4, 4]);
      await recalculateVendorStats(vendor.vendor_id);
      console.log(`Flexible-qualified ${v.business_name} (+${created} reviews).`);
      flexibleCount++;
    } else if (v.tier === 'high') {
      await setPackages(vendor.vendor_id, [{
        package_id: crypto.randomUUID(),
        tier: 'luxury',
        title: `${v.category} Luxury Package`,
        price: v.price_max,
        inclusions: LUXURY_INCLUSIONS[v.category],
      }]);
      const created = await ensureFeedback(vendor, couples, [5, 5, 5, 4, 5, 5, 5, 4, 5, 5]);
      await recalculateVendorStats(vendor.vendor_id);
      console.log(`High-Class-qualified ${v.business_name} (+${created} reviews).`);
      highCount++;
    }
  }

  console.log(
    `\nDone. Flexible-qualified: ${flexibleCount}, High-Class-qualified: ${highCount}`
    + `${missing ? `, missing vendors: ${missing}` : ''}.`,
  );
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to qualify vendor classes:', err.message);
  process.exit(1);
});

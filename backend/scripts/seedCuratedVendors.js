// One-off dev seeding script — inserts WedPilot's curated vendor catalog as
// real database rows, so these vendors work everywhere (discovery, dashboard,
// vendor detail, wishlist, booking, feedback) instead of only ever appearing
// inside AI budget matching, which read them from a frontend-only Dart
// catalog (lib/core/constants/curated_vendors.dart, now removed).
//
// Source data: curated_vendors_export.json, produced by running
//   dart run tool/export_curated_vendors.dart
// from the repo root — that dumps CuratedVendors.all (the original Dart
// catalog) via VendorProfile.toJson(), which already uses the exact same
// snake_case field names as these Sequelize models.
//
// Idempotent — every curated vendor gets a deterministic
// `<original-id>@wedpilot-curated.internal` email, so re-running this script
// just skips whatever already exists. See removeCuratedVendors.js for the
// deletion counterpart (matches the same email domain).
//
// Usage: node scripts/seedCuratedVendors.js
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const sequelize = require('../db/sequelize');
const User = require('../db/models/user');
const Vendor = require('../db/models/vendor');
const VendorService = require('../db/models/vendorService');
const VendorStats = require('../db/models/vendorStats');

const CURATED_PASSWORD = 'CuratedVendor123!';
const EMAIL_DOMAIN = 'wedpilot-curated.internal';
const EXPORT_PATH = path.join(__dirname, 'curated_vendors_export.json');

// Guest Capacity is mandatory on every real listing (see routes/vendors.js);
// the exported catalog predates that requirement, so any service missing it
// gets a computed one instead of being seeded with null. [minCapacity,
// maxCapacity] per category, mirroring backfillGuestCapacity.js — a flat
// per-category number would make every vendor in a category tie on guest
// capacity, so this scales by price within the category instead (cheaper
// package → lower end, pricier → higher end), giving each vendor a real,
// differentiated value the same way price already varies per vendor.
const CATEGORY_GUEST_RANGES = {
  Catering: [80, 500],
  'Tent Hire': [100, 800],
  Photography: [50, 400],
  Decoration: [80, 600],
  Venue: [100, 800],
};
const DEFAULT_GUEST_RANGE = [50, 300];
const roundToStep = (n, step = 25) => Math.round(n / step) * step;

/// Precomputes a capacity for every service missing max_guests, ranked by
/// price against only the other missing-capacity services in that same
/// category (services that already state a capacity aren't touched or used
/// as ranking context — they're the vendor's own real, declared number).
function computeGuestCapacities(vendors) {
  const byCategory = {};
  for (const v of vendors) {
    for (const s of v.services) {
      if (s.max_guests != null) continue;
      (byCategory[v.category] ??= []).push(s);
    }
  }
  const capacityByService = new Map();
  for (const [category, services] of Object.entries(byCategory)) {
    const [minCapacity, maxCapacity] = CATEGORY_GUEST_RANGES[category] ?? DEFAULT_GUEST_RANGE;
    const ranked = [...services].sort((a, b) => (a.price_min + a.price_max) - (b.price_min + b.price_max));
    ranked.forEach((s, i) => {
      const position = ranked.length === 1 ? 0.5 : i / (ranked.length - 1);
      capacityByService.set(s, roundToStep(minCapacity + position * (maxCapacity - minCapacity)));
    });
  }
  return capacityByService;
}

async function main() {
  if (!fs.existsSync(EXPORT_PATH)) {
    throw new Error(
      `${EXPORT_PATH} not found — run "dart run tool/export_curated_vendors.dart" from the repo root first.`
    );
  }
  const vendors = JSON.parse(fs.readFileSync(EXPORT_PATH, 'utf8'));
  const computedGuestCapacity = computeGuestCapacities(vendors);

  await sequelize.authenticate();
  const password_hash = await bcrypt.hash(CURATED_PASSWORD, 10);

  let created = 0;
  let skipped = 0;

  for (const v of vendors) {
    const email = `${v.vendor_id}@${EMAIL_DOMAIN}`;

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      console.log(`Skipping ${v.business_name} — ${email} already exists.`);
      skipped += 1;
      continue;
    }

    const user = await User.create({
      email,
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
      tier: v.tier,
      verification_status: v.verification_status,
      style_tags: v.style_tags,
      phone: v.phone,
      packages: v.packages,
    });

    for (const s of v.services) {
      await VendorService.create({
        vendor_id: vendor.vendor_id,
        title: s.title,
        description: s.description,
        price_min: s.price_min,
        price_max: s.price_max,
        unit: s.unit,
        is_active: s.is_active,
        max_guests: s.max_guests ?? computedGuestCapacity.get(s) ?? 150,
      });
    }

    // Set directly rather than derived from fabricated feedback/inquiry rows
    // — the curated catalog's rating/review/composite numbers are already
    // the intended final values per tier, and the API serves these fields
    // straight from vendor_stats (see serializeVendor() in routes/vendors.js).
    await VendorStats.create({
      vendor_id: vendor.vendor_id,
      avg_star_rating: v.rating,
      feedback_count: v.feedback_count,
      completed_weddings_count: v.weddings_completed,
      avg_response_time_minutes: v.responds_in_minutes,
      on_time_rate: v.on_time_rate,
      recommend_rate: v.recommend_rate,
      is_verified_business: v.verification_status === 'verified',
      crs_score: v.composite_score,
      last_calculated_at: new Date(),
    });

    console.log(`Created ${v.business_name} (${v.category}, ${v.location}) — login: ${email} / ${CURATED_PASSWORD}`);
    created += 1;
  }

  console.log(`\nDone. Created ${created}, skipped ${skipped} (already existed).`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to seed curated vendors:', err.message);
  process.exit(1);
});

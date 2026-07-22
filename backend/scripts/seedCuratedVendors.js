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

async function main() {
  if (!fs.existsSync(EXPORT_PATH)) {
    throw new Error(
      `${EXPORT_PATH} not found — run "dart run tool/export_curated_vendors.dart" from the repo root first.`
    );
  }
  const vendors = JSON.parse(fs.readFileSync(EXPORT_PATH, 'utf8'));

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

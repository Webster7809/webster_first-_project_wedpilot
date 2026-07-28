// Production-safe migration script for the Guest Capacity feature.
// `vendor_services.max_guests` became a mandatory field on every new/edited
// listing (see POST/PUT /me/services in routes/vendors.js), but the column
// itself stays nullable in the model (see db/models/vendorService.js) so
// `sequelize.sync({ alter: true })` never fails against rows created before
// this requirement existed. This script is the other half of that migration:
// it assigns every such legacy row a sensible guest capacity so existing
// listings stay visible to search/AI matching instead of being silently
// starved by the new mandatory-capacity checks. Vendors can revise the
// assigned number at any time from their listing edit screen.
//
// Capacity is scaled by each listing's price *within its own category* —
// a cheap package and a luxury package charging 5x more realistically don't
// serve the same party size, and giving every listing in a category the
// exact same flat number would make guest capacity useless as a matching
// signal (every vendor would tie). Ranking by price and spreading linearly
// across the category's capacity range means AI matching actually has
// something to differentiate on.
//
// Idempotent — only touches rows where max_guests IS NULL, so it's safe to
// run more than once (e.g. after a fresh seed adds new legacy-shaped rows).
//
// Usage: node scripts/backfillGuestCapacity.js
require('dotenv').config();
const sequelize = require('../db/sequelize');
const Vendor = require('../db/models/vendor');
const VendorService = require('../db/models/vendorService');

// [minCapacity, maxCapacity] per category — the cheapest listing in a
// category lands near the low end, the priciest near the high end. Any
// category not listed here (including vendor-registered custom categories)
// falls back to DEFAULT_RANGE.
const CATEGORY_RANGES = {
  Catering: [80, 500],
  'Tent Hire': [100, 800],
  Photography: [50, 400],
  Decoration: [80, 600],
  Venue: [100, 800],
};
const DEFAULT_RANGE = [50, 300];

// Rounds to the nearest 25 so assigned numbers read like a deliberate
// capacity ("275 guests") rather than an obviously-computed one ("263").
const roundToStep = (n, step = 25) => Math.round(n / step) * step;

async function main() {
  await sequelize.authenticate();

  const orphanServices = await VendorService.findAll({ where: { max_guests: null } });
  if (orphanServices.length === 0) {
    console.log('No listings missing guest capacity — nothing to backfill.');
    process.exit(0);
  }

  const vendorIds = [...new Set(orphanServices.map((s) => s.vendor_id))];
  const vendors = await Vendor.findAll({ where: { vendor_id: vendorIds } });
  const categoryByVendorId = Object.fromEntries(vendors.map((v) => [v.vendor_id, v.category]));

  // Rank orphan services by price *within their own category* so the price
  // comparison is apples-to-apples — a photographer and a venue are priced
  // on completely different scales (mirrors VendorFilteringService.relativePriceTiers
  // on the Flutter side).
  const byCategory = {};
  for (const service of orphanServices) {
    const category = categoryByVendorId[service.vendor_id] ?? 'Unknown';
    (byCategory[category] ??= []).push(service);
  }

  let updated = 0;
  const perCategoryCount = {};
  for (const [category, services] of Object.entries(byCategory)) {
    const [minCapacity, maxCapacity] = CATEGORY_RANGES[category] ?? DEFAULT_RANGE;
    const ranked = [...services].sort(
      (a, b) => (Number(a.price_min) + Number(a.price_max)) - (Number(b.price_min) + Number(b.price_max)),
    );

    for (let i = 0; i < ranked.length; i++) {
      // Single-listing categories get the range midpoint rather than the floor.
      const position = ranked.length === 1 ? 0.5 : i / (ranked.length - 1);
      const capacity = roundToStep(minCapacity + position * (maxCapacity - minCapacity));
      ranked[i].set({ max_guests: capacity });
      await ranked[i].save();
      updated += 1;
    }
    perCategoryCount[category] = services.length;
  }

  console.log(`Backfilled max_guests on ${updated} listing(s), scaled by price within each category:`);
  for (const [category, count] of Object.entries(perCategoryCount)) {
    const [minCapacity, maxCapacity] = CATEGORY_RANGES[category] ?? DEFAULT_RANGE;
    console.log(`  ${category}: ${count} listing(s) spread across ${minCapacity}-${maxCapacity} guests`);
  }
  console.log('Done. Affected vendors should review and adjust their assigned capacity.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to backfill guest capacity:', err.message);
  process.exit(1);
});

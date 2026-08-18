const { VendorPackage, VendorPackageInclusion } = require('../db/models/vendorPackage');

/**
 * The only place that reads or writes vendor packages.
 *
 * Rebuilds the exact JSON shape the API has always emitted —
 * `[{ package_id, tier, title, inclusions: [...], price }]` — so the two-table
 * storage is invisible to the routes, the app and the AI matcher.
 */

const MAX_PACKAGES = 6;
const MAX_INCLUSIONS = 10;

function toApiShape(pkg, inclusions) {
  return {
    package_id: pkg.package_id,
    tier: pkg.tier,
    title: pkg.title,
    inclusions: inclusions.map((i) => i.description),
    price: pkg.price == null ? null : Number(pkg.price),
  };
}

async function packagesFor(vendorId) {
  const map = await packagesForVendors([vendorId]);
  return map[vendorId] ?? [];
}

/// Batched for list endpoints — two queries for a whole page rather than two
/// per vendor.
async function packagesForVendors(vendorIds) {
  const result = Object.fromEntries(vendorIds.map((id) => [id, []]));
  if (vendorIds.length === 0) return result;

  const packages = await VendorPackage.findAll({
    where: { vendor_id: vendorIds },
    order: [['sort_order', 'ASC']],
  });
  if (packages.length === 0) return result;

  const inclusions = await VendorPackageInclusion.findAll({
    where: { package_id: packages.map((p) => p.package_id) },
    order: [['sort_order', 'ASC']],
  });
  const byPackage = {};
  for (const inc of inclusions) {
    (byPackage[inc.package_id] ??= []).push(inc);
  }

  for (const pkg of packages) {
    (result[pkg.vendor_id] ??= []).push(
      toApiShape(pkg, byPackage[pkg.package_id] ?? []),
    );
  }
  return result;
}

/// Replaces a vendor's whole package list with [packages], which must already
/// be validated (see the route). Returns them in API shape.
async function setPackages(vendorId, packages) {
  const existing = await VendorPackage.findAll({
    where: { vendor_id: vendorId },
    attributes: ['package_id'],
  });
  if (existing.length > 0) {
    await VendorPackageInclusion.destroy({
      where: { package_id: existing.map((p) => p.package_id) },
    });
    await VendorPackage.destroy({ where: { vendor_id: vendorId } });
  }

  for (const [index, pkg] of packages.entries()) {
    await VendorPackage.create({
      package_id: pkg.package_id,
      vendor_id: vendorId,
      tier: pkg.tier,
      title: pkg.title,
      price: pkg.price,
      sort_order: index,
    });
    await VendorPackageInclusion.bulkCreate(
      pkg.inclusions.map((description, i) => ({
        package_id: pkg.package_id,
        sort_order: i,
        description,
      })),
    );
  }

  return packagesFor(vendorId);
}

module.exports = {
  packagesFor,
  packagesForVendors,
  setPackages,
  MAX_PACKAGES,
  MAX_INCLUSIONS,
};

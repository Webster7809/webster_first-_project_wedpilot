// ONE-OFF DATA FIX — run once against an environment whose vendor_media rows
// still hold pre-fix Lorem Picsum URLs from an earlier seedZambianVendors.js
// run (see that script's git history: it used to seed
// `https://picsum.photos/seed/...` — random stock photography with zero
// connection to the vendor's actual category). Editing that script only
// changes what a *future* run inserts; it does nothing for rows already in
// the database. This backfills those existing rows to the same
// category-correct curated Pexels photos the fixed script now seeds.
//
// Usage: node scripts/fixSeededVendorPhotos.js [--dry-run]
require('dotenv').config();
const { Op } = require('sequelize');
const sequelize = require('../db/sequelize');
const Vendor = require('../db/models/vendor');
const VendorMedia = require('../db/models/vendorMedia');

// Kept in sync with the same map in seedZambianVendors.js and the Flutter
// fallback (lib/core/constants/vendor_category_images.dart).
const PHOTO_IDS_BY_CATEGORY = {
  Venue: [33852468, 17001763, 3376771, 12688997, 32142669],
  Catering: [28976236, 28976230, 28976228, 37976911, 29587700],
  Photography: [35325793, 37754302, 21560369, 18864880, 17169150],
  'Decor & flowers': [31138818, 4646001, 12876507, 31517333, 32657514],
  'DJ & MC': [27018254, 32601989, 12473542, 1749822, 29315604],
  Transport: [37828108, 13044866, 19894151, 18433155, 29240263],
  'Wedding attire': [27269998, 20194301, 16625625, 4637461, 15120548],
  'Cake & sweets': [11712500, 17315403, 30445121, 24838552, 19870076],
};

function pexelsUrl(id, width) {
  return `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=${width}`;
}

function hashString(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  await sequelize.authenticate();

  const stalePhotos = await VendorMedia.findAll({
    where: { url: { [Op.like]: '%picsum.photos%' } },
    order: [['vendor_id', 'ASC'], ['sort_order', 'ASC']],
  });
  if (stalePhotos.length === 0) {
    console.log('No picsum.photos rows found — nothing to do.');
    process.exit(0);
  }

  const vendorIds = [...new Set(stalePhotos.map((m) => m.vendor_id))];
  const vendors = await Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } });
  const vendorById = new Map(vendors.map((v) => [v.vendor_id, v]));

  let updated = 0;
  let skippedNoVendor = 0;
  let skippedUnknownCategory = 0;

  for (const media of stalePhotos) {
    const vendor = vendorById.get(media.vendor_id);
    if (!vendor) {
      skippedNoVendor++;
      continue;
    }
    const ids = PHOTO_IDS_BY_CATEGORY[vendor.category];
    if (!ids) {
      skippedUnknownCategory++;
      continue;
    }
    const offset = hashString(vendor.business_name) % ids.length;
    const id = ids[(offset + media.sort_order) % ids.length];
    const newUrl = pexelsUrl(id, 1200);
    const newThumb = pexelsUrl(id, 400);

    if (dryRun) {
      console.log(
        `[dry-run] ${vendor.business_name} (${vendor.category}) sort_order=${media.sort_order}: `
        + `${media.url} -> ${newUrl}`,
      );
    } else {
      media.url = newUrl;
      media.thumbnail_url = newThumb;
      await media.save();
    }
    updated++;
  }

  console.log(
    `${dryRun ? '[dry-run] would update' : 'Updated'} ${updated} media row(s) `
    + `across ${vendorIds.length} vendor(s).`,
  );
  if (skippedNoVendor) console.log(`Skipped ${skippedNoVendor} row(s) with no matching vendor.`);
  if (skippedUnknownCategory) console.log(`Skipped ${skippedUnknownCategory} row(s) with an unrecognised category.`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to fix seeded vendor photos:', err.message);
  process.exit(1);
});

const { VendorStyleTag, CoupleStyleTag } = require('../db/models/styleTag');

/**
 * The only place that reads or writes style tags.
 *
 * Callers keep handing arrays of strings around exactly as before — the move
 * from a JSON column to rows stops at this boundary, so the API shape and the
 * Flutter models are untouched.
 */

const MAX_TAG_LENGTH = 60;

/// Trims, drops blanks and duplicates, and enforces the column width. Tags
/// arrive from vendor onboarding and the couple's wizard, so they cannot be
/// trusted to be clean.
function normalise(tags) {
  if (!Array.isArray(tags)) return [];
  const seen = new Set();
  for (const raw of tags) {
    if (typeof raw !== 'string') continue;
    const tag = raw.trim().slice(0, MAX_TAG_LENGTH);
    if (tag) seen.add(tag);
  }
  return [...seen];
}

function makeAccessors(Model, ownerKey) {
  return {
    async get(ownerId) {
      const rows = await Model.findAll({
        where: { [ownerKey]: ownerId },
        order: [['tag', 'ASC']],
      });
      return rows.map((r) => r.tag);
    },

    /// Batched for list endpoints — one query for a whole page rather than
    /// one per row.
    async getMany(ownerIds) {
      const result = Object.fromEntries(ownerIds.map((id) => [id, []]));
      if (ownerIds.length === 0) return result;
      const rows = await Model.findAll({
        where: { [ownerKey]: ownerIds },
        order: [['tag', 'ASC']],
      });
      for (const row of rows) {
        (result[row[ownerKey]] ??= []).push(row.tag);
      }
      return result;
    },

    async set(ownerId, tags) {
      const wanted = normalise(tags);
      await Model.destroy({ where: { [ownerKey]: ownerId } });
      if (wanted.length > 0) {
        await Model.bulkCreate(
          wanted.map((tag) => ({ [ownerKey]: ownerId, tag })),
        );
      }
      return wanted.sort();
    },
  };
}

const vendor = makeAccessors(VendorStyleTag, 'vendor_id');
const couple = makeAccessors(CoupleStyleTag, 'couple_user_id');

module.exports = {
  normalise,
  MAX_TAG_LENGTH,
  vendorStyleTags: vendor.get,
  vendorStyleTagsFor: vendor.getMany,
  setVendorStyleTags: vendor.set,
  coupleStyleTags: couple.get,
  coupleStyleTagsFor: couple.getMany,
  setCoupleStyleTags: couple.set,
};

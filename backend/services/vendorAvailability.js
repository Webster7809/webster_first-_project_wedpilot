const VendorBlockedDate = require('../db/models/vendorBlockedDate');

/**
 * The only place that reads or writes vendor availability.
 *
 * Dates are handled as 'YYYY-MM-DD' strings throughout, matching what the API
 * has always emitted and what the Flutter client parses — the storage change
 * from a JSON array to rows is deliberately invisible above this module.
 */

const toIso = (value) => {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
};

/// Blocked dates for one vendor, ascending.
async function blockedDatesFor(vendorId) {
  const rows = await VendorBlockedDate.findAll({
    where: { vendor_id: vendorId },
    order: [['blocked_date', 'ASC']],
  });
  return rows.map((r) => toIso(r.blocked_date));
}

/// Blocked dates for many vendors at once, as { vendorId: ['YYYY-MM-DD'] }.
///
/// The list endpoint serialises a page of vendors, so fetching per vendor
/// would be an N+1 — the same reason vendor stats are already batched.
async function blockedDatesForVendors(vendorIds) {
  const result = Object.fromEntries(vendorIds.map((id) => [id, []]));
  if (vendorIds.length === 0) return result;

  const rows = await VendorBlockedDate.findAll({
    where: { vendor_id: vendorIds },
    order: [['blocked_date', 'ASC']],
  });
  for (const row of rows) {
    (result[row.vendor_id] ??= []).push(toIso(row.blocked_date));
  }
  return result;
}

/// Adds one date. Idempotent — the composite primary key makes a repeat a
/// no-op rather than a duplicate.
async function blockDate(vendorId, date) {
  await VendorBlockedDate.findOrCreate({
    where: { vendor_id: vendorId, blocked_date: toIso(date) },
  });
}

/// Removes one date. Returns true when a row was actually deleted, so callers
/// can tell "released" from "was never blocked".
async function releaseDate(vendorId, date) {
  const removed = await VendorBlockedDate.destroy({
    where: { vendor_id: vendorId, blocked_date: toIso(date) },
  });
  return removed > 0;
}

/// Replaces a vendor's whole calendar with [dates].
async function setBlockedDates(vendorId, dates) {
  const wanted = [...new Set(dates.map(toIso))];
  await VendorBlockedDate.destroy({ where: { vendor_id: vendorId } });
  if (wanted.length > 0) {
    await VendorBlockedDate.bulkCreate(
      wanted.map((d) => ({ vendor_id: vendorId, blocked_date: d })),
    );
  }
  return wanted.sort();
}

async function isBlocked(vendorId, date) {
  const row = await VendorBlockedDate.findOne({
    where: { vendor_id: vendorId, blocked_date: toIso(date) },
  });
  return row != null;
}

module.exports = {
  blockedDatesFor,
  blockedDatesForVendors,
  blockDate,
  releaseDate,
  setBlockedDates,
  isBlocked,
};

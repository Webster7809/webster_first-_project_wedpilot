// Shared validation for a vendor listing's stated serving capacity — used by
// both the vendor's own listing routes (routes/vendors.js) and the admin
// capacity-correction route (routes/admin.js), so the rule (and the ceiling
// itself) can never drift between the two entry points.
const MAX_REALISTIC_GUEST_COUNT = 20000;

function validateMaxGuests(value) {
  if (!Number.isInteger(value) || value <= 0 || value > MAX_REALISTIC_GUEST_COUNT) {
    return `max_guests is required and must be a whole number between 1 and ${MAX_REALISTIC_GUEST_COUNT}.`;
  }
  return null;
}

module.exports = { MAX_REALISTIC_GUEST_COUNT, validateMaxGuests };

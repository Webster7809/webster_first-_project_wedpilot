// Shared card-number generation — used by both routes/guests.js (couple adds
// a guest directly) and routes/invitations.js (a guest self-registers via the
// public share link), so every guest record gets one the same way regardless
// of how it was created. A 6-digit numeric code is short enough to write by
// hand on a physical invitation card or read aloud at the door, unlike
// invite_token's 16-char hex string, which exists for URLs, not people.
const Guest = require('../db/models/guest');

async function generateCardNumber() {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const existing = await Guest.findOne({ where: { card_number: code } });
    if (!existing) return code;
  }
  throw new Error('Could not generate a unique card number.');
}

module.exports = { generateCardNumber };

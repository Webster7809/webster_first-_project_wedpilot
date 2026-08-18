const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

const { setupDatabase, truncateAll, closeDatabase } = require('./helpers/db');

let User;
let Vendor;
let Inquiry;
let Notification;
let applyInquiryStatus;
let InquiryStatusError;
let blockedDatesFor;

const WEDDING_DAY = '2026-09-12';

/// Stands in for the route's own resolveWeddingDate, which reads the couple's
/// profile — the transition rules don't care where the date came from.
const resolveWeddingDate = async (inquiry) => inquiry.wedding_date || WEDDING_DAY;

before(async () => {
  await setupDatabase();
  User = require('../db/models/user');
  Vendor = require('../db/models/vendor');
  Inquiry = require('../db/models/inquiry');
  Notification = require('../db/models/notification');
  ({ applyInquiryStatus, InquiryStatusError } = require('../services/inquiryStatus'));
  ({ blockedDatesFor } = require('../services/vendorAvailability'));
});

after(closeDatabase);
beforeEach(truncateAll);

let seq = 0;
const uuid = () => `00000000-0000-4000-8000-${String(++seq).padStart(12, '0')}`;

/// Real rows, not loose UUIDs: the schema has foreign keys now, so a fixture
/// that invents a parent id is rejected by the database — which is the point.
async function makeUser(role, overrides = {}) {
  const id = uuid();
  return User.create({
    user_id: id,
    name: `${role}-${id.slice(-4)}`,
    email: `${role}-${id.slice(-4)}@example.test`,
    password_hash: 'x',
    role,
    ...overrides,
  });
}

async function makeVendor(overrides = {}) {
  const owner = await makeUser('vendor');
  return Vendor.create({
    vendor_id: uuid(),
    user_id: owner.user_id,
    business_name: 'Kabwe Bridal',
    category: 'Attire',
    location: 'Ndola',
    ...overrides,
  });
}

async function makeCouple() {
  const user = await makeUser('couple');
  return user.user_id;
}

async function makeInquiry(vendor, overrides = {}) {
  const coupleUserId = overrides.couple_user_id || (await makeCouple());
  return Inquiry.create({
    inquiry_id: uuid(),
    vendor_id: vendor.vendor_id,
    message: 'Are you free?',
    status: 'viewed',
    ...overrides,
    couple_user_id: coupleUserId,
  });
}

// ── Accept ────────────────────────────────────────────────────────────────────

test('accepting holds the wedding date on the vendor calendar', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });

  await applyInquiryStatus({
    vendor, inquiry, status: 'booked', resolveWeddingDate,
  });

  assert.deepEqual(
    await blockedDatesFor(vendor.vendor_id), [WEDDING_DAY]);
  assert.equal(inquiry.status, 'booked');
});

test('accepting notifies the couple', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });

  await applyInquiryStatus({
    vendor, inquiry, status: 'booked', resolveWeddingDate,
  });

  const notes = await Notification.findAll({
    where: { user_id: inquiry.couple_user_id, type: 'booking_accepted' },
  });
  assert.equal(notes.length, 1);
});

test('a second booking on the same date is refused', async () => {
  const vendor = await makeVendor();
  const first = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });
  await applyInquiryStatus({
    vendor, inquiry: first, status: 'booked', resolveWeddingDate,
  });

  const second = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });
  await assert.rejects(
    () => applyInquiryStatus({
      vendor, inquiry: second, status: 'booked', resolveWeddingDate,
    }),
    (err) => err instanceof InquiryStatusError && err.status === 409,
  );

  await second.reload();
  assert.equal(second.status, 'viewed', 'the refused inquiry must not change status');
});

// ── Undo ──────────────────────────────────────────────────────────────────────

test('undoing an accept releases the calendar hold', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });

  await applyInquiryStatus({
    vendor, inquiry, status: 'booked', resolveWeddingDate,
  });
  await applyInquiryStatus({
    vendor, inquiry, status: 'viewed', resolveWeddingDate,
  });

  assert.deepEqual(
    await blockedDatesFor(vendor.vendor_id), [],
    'the vendor stays blocked on a day that is free again',
  );
  assert.equal(inquiry.status, 'viewed');
});

test('undoing an accept deletes the "confirmed!" notification', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });

  await applyInquiryStatus({
    vendor, inquiry, status: 'booked', resolveWeddingDate,
  });
  await applyInquiryStatus({
    vendor, inquiry, status: 'viewed', resolveWeddingDate,
  });

  const notes = await Notification.findAll({
    where: { user_id: inquiry.couple_user_id, type: 'booking_accepted' },
  });
  assert.equal(notes.length, 0, 'the couple keeps a confirmation that was reversed');
});

test('undo frees the date for a different couple to book', async () => {
  const vendor = await makeVendor();
  const first = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });
  await applyInquiryStatus({
    vendor, inquiry: first, status: 'booked', resolveWeddingDate,
  });
  await applyInquiryStatus({
    vendor, inquiry: first, status: 'viewed', resolveWeddingDate,
  });

  const second = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });
  await applyInquiryStatus({
    vendor, inquiry: second, status: 'booked', resolveWeddingDate,
  });

  assert.equal(second.status, 'booked');
  assert.deepEqual(await blockedDatesFor(vendor.vendor_id), [WEDDING_DAY]);
});

test('undo leaves an older acceptance for the same vendor alone', async () => {
  const vendor = await makeVendor();
  const couple = await makeCouple();

  // An earlier, still-valid booking with the same couple and vendor.
  const older = await makeInquiry(vendor, {
    couple_user_id: couple,
    wedding_date: '2026-05-02',
  });
  await applyInquiryStatus({
    vendor, inquiry: older, status: 'booked', resolveWeddingDate,
  });

  const newer = await makeInquiry(vendor, {
    couple_user_id: couple,
    wedding_date: WEDDING_DAY,
  });
  await applyInquiryStatus({
    vendor, inquiry: newer, status: 'booked', resolveWeddingDate,
  });
  await applyInquiryStatus({
    vendor, inquiry: newer, status: 'viewed', resolveWeddingDate,
  });

  const notes = await Notification.findAll({
    where: { user_id: couple, type: 'booking_accepted' },
  });
  assert.equal(notes.length, 1, 'the undo deleted an unrelated, still-valid acceptance');
});

// ── Decline ───────────────────────────────────────────────────────────────────

test('declining requires a reason', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor);

  for (const reason of [undefined, '', '   ']) {
    await assert.rejects(
      () => applyInquiryStatus({
        vendor, inquiry, status: 'declined', declineReason: reason, resolveWeddingDate,
      }),
      (err) => err instanceof InquiryStatusError && err.status === 400,
    );
  }
});

test('a decline reason over 300 characters is refused', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor);

  await assert.rejects(
    () => applyInquiryStatus({
      vendor, inquiry, status: 'declined', declineReason: 'x'.repeat(301), resolveWeddingDate,
    }),
    (err) => err instanceof InquiryStatusError && err.status === 400,
  );
});

test('declining stores the reason and notifies the couple', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor);

  await applyInquiryStatus({
    vendor, inquiry, status: 'declined', declineReason: '  Fully booked  ', resolveWeddingDate,
  });

  assert.equal(inquiry.status, 'declined');
  assert.equal(inquiry.decline_reason, 'Fully booked', 'reason should be trimmed');

  const notes = await Notification.findAll({
    where: { user_id: inquiry.couple_user_id, type: 'booking_declined' },
  });
  assert.equal(notes.length, 1);
});

test('declining a confirmed booking also releases the date', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });

  await applyInquiryStatus({
    vendor, inquiry, status: 'booked', resolveWeddingDate,
  });
  await applyInquiryStatus({
    vendor, inquiry, status: 'declined', declineReason: 'Had to cancel', resolveWeddingDate,
  });

  assert.deepEqual(
    await blockedDatesFor(vendor.vendor_id), []);
});

// ── Validation ────────────────────────────────────────────────────────────────

test('an unknown status is refused', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor);

  await assert.rejects(
    () => applyInquiryStatus({
      vendor, inquiry, status: 'cancelled', resolveWeddingDate,
    }),
    (err) => err instanceof InquiryStatusError && err.status === 400,
  );
});

test('accepting twice does not duplicate the blocked date', async () => {
  const vendor = await makeVendor();
  const inquiry = await makeInquiry(vendor, { wedding_date: WEDDING_DAY });

  await applyInquiryStatus({ vendor, inquiry, status: 'booked', resolveWeddingDate });
  await applyInquiryStatus({ vendor, inquiry, status: 'booked', resolveWeddingDate });

  assert.deepEqual(
    await blockedDatesFor(vendor.vendor_id), [WEDDING_DAY]);
});

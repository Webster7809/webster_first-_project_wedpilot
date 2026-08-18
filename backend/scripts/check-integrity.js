// Read-only integrity census: counts rows whose parent no longer exists.
// A foreign key cannot be added to a relationship that already has orphans,
// so this decides what has to be cleaned before constraints go on.
require('dotenv').config();
const mysql = require('mysql2/promise');

// child table, child column, parent table, parent key
const RELATIONSHIPS = [
  ['vendors', 'user_id', 'users', 'user_id'],
  ['couple_profiles', 'user_id', 'users', 'user_id'],
  ['inquiries', 'vendor_id', 'vendors', 'vendor_id'],
  ['inquiries', 'couple_user_id', 'users', 'user_id'],
  ['vendor_services', 'vendor_id', 'vendors', 'vendor_id'],
  ['vendor_media', 'vendor_id', 'vendors', 'vendor_id'],
  ['vendor_feedback', 'vendor_id', 'vendors', 'vendor_id'],
  ['vendor_feedback', 'couple_user_id', 'users', 'user_id'],
  ['vendor_stats', 'vendor_id', 'vendors', 'vendor_id'],
  ['vendor_matches', 'couple_user_id', 'users', 'user_id'],
  ['budgets', 'couple_user_id', 'users', 'user_id'],
  ['budget_categories', 'budget_id', 'budgets', 'budget_id'],
  ['budget_custom_items', 'budget_id', 'budgets', 'budget_id'],
  ['expenses', 'budget_id', 'budgets', 'budget_id'],
  ['tasks', 'couple_user_id', 'users', 'user_id'],
  ['guests', 'couple_user_id', 'users', 'user_id'],
  ['invitations', 'couple_user_id', 'users', 'user_id'],
  ['rsvp_responses', 'invitation_id', 'invitations', 'invitation_id'],
  ['notifications', 'user_id', 'users', 'user_id'],
  ['conversations', 'couple_user_id', 'users', 'user_id'],
  ['conversations', 'vendor_id', 'vendors', 'vendor_id'],
  ['messages', 'convo_id', 'conversations', 'convo_id'],
  ['saved_vendors', 'couple_user_id', 'users', 'user_id'],
  ['saved_vendors', 'vendor_id', 'vendors', 'vendor_id'],
];

(async () => {
  const db = process.env.DB_NAME;
  const c = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: db,
  });

  const [cols] = await c.query(
    'SELECT TABLE_NAME t, COLUMN_NAME col, IS_NULLABLE nullable FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=?',
    [db],
  );
  const exists = new Map();
  for (const r of cols) exists.set(`${r.t}.${r.col}`, r.nullable === 'YES');

  console.log(`database: ${db}\n`);
  console.log(
    'child.column'.padEnd(38) + 'rows'.padStart(7) + 'orphans'.padStart(9) + '  nullable',
  );
  console.log('-'.repeat(66));

  let totalOrphans = 0;
  const problems = [];

  for (const [child, col, parent, key] of RELATIONSHIPS) {
    const path = `${child}.${col}`;
    if (!exists.has(path) || !exists.has(`${parent}.${key}`)) {
      console.log(path.padEnd(38) + '   — column or table not present');
      continue;
    }
    const nullable = exists.get(path);
    const [[{ n: rows }]] = await c.query(`SELECT COUNT(*) n FROM \`${child}\``);
    const [[{ n: orphans }]] = await c.query(
      `SELECT COUNT(*) n FROM \`${child}\` ch
       LEFT JOIN \`${parent}\` p ON ch.\`${col}\` = p.\`${key}\`
       WHERE ch.\`${col}\` IS NOT NULL AND p.\`${key}\` IS NULL`,
    );
    totalOrphans += orphans;
    if (orphans > 0) problems.push([path, orphans]);
    console.log(
      path.padEnd(38) +
        String(rows).padStart(7) +
        String(orphans).padStart(9) +
        '  ' +
        (nullable ? 'yes' : 'NO'),
    );
  }

  console.log('-'.repeat(66));
  if (totalOrphans === 0) {
    console.log('No orphans. Every relationship can take a foreign key as-is.');
  } else {
    console.log(`${totalOrphans} orphaned row(s) across ${problems.length} relationship(s):`);
    for (const [p, n] of problems) console.log(`  ${p}: ${n}`);
    console.log('These must be cleaned or nulled before constraints are added.');
  }

  await c.end();
})().catch((e) => {
  console.error('FAILED:', e.message);
  process.exit(1);
});

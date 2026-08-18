/**
 * Adds the foreign keys the schema never had — it was running with zero
 * referential integrity, entirely application-enforced.
 *
 * That is not theoretical: `scripts/removeTestVendors.js` deleted users
 * without their dependent rows and left 3 vendors, 2 couple profiles and 2
 * notifications pointing at users that no longer exist. This migration
 * removes those first (a constraint cannot be added over an orphan) and then
 * stops it happening again.
 *
 * ## Delete behaviour
 *
 * CASCADE for data that only exists for its parent — a couple's budget,
 * tasks, guests and notifications mean nothing without the couple, and a
 * vendor's services, media and stats mean nothing without the vendor.
 *
 * RESTRICT for shared history. An inquiry belongs to a couple *and* a vendor,
 * and a review is a record both parties rely on; cascading either side would
 * let one person's deletion silently erase the other's booking history. The
 * cost is that a party with live bookings can no longer be hard-deleted —
 * that needs an explicit archive/soft-delete flow, which the app does not
 * have yet. Failing loudly is the right side to err on.
 */

/// Orphan cleanup is derived from FOREIGN_KEYS below rather than hand-listed,
/// and repeated until a pass deletes nothing.
///
/// Both parts matter. A hand-written list goes stale the moment a constraint
/// is added, and one pass is not enough: deleting an orphaned vendor orphans
/// its vendor_stats row in turn, which then fails its own constraint. Looping
/// to a fixed point handles that chain at any depth.
const MAX_CLEANUP_PASSES = 10;

// child table, child column, parent table, parent key, onDelete
const FOREIGN_KEYS = [
  // ── Owned by a user ──────────────────────────────────────────────────────
  ['vendors', 'user_id', 'users', 'user_id', 'CASCADE'],
  ['couple_profiles', 'user_id', 'users', 'user_id', 'CASCADE'],
  ['budgets', 'couple_user_id', 'users', 'user_id', 'CASCADE'],
  ['tasks', 'couple_user_id', 'users', 'user_id', 'CASCADE'],
  ['guests', 'couple_user_id', 'users', 'user_id', 'CASCADE'],
  ['invitations', 'couple_user_id', 'users', 'user_id', 'CASCADE'],
  ['notifications', 'user_id', 'users', 'user_id', 'CASCADE'],
  ['vendor_matches', 'couple_user_id', 'users', 'user_id', 'CASCADE'],
  ['saved_vendors', 'couple_user_id', 'users', 'user_id', 'CASCADE'],
  ['conversations', 'couple_user_id', 'users', 'user_id', 'CASCADE'],

  // ── Owned by a vendor ────────────────────────────────────────────────────
  ['vendor_services', 'vendor_id', 'vendors', 'vendor_id', 'CASCADE'],
  ['vendor_media', 'vendor_id', 'vendors', 'vendor_id', 'CASCADE'],
  ['vendor_stats', 'vendor_id', 'vendors', 'vendor_id', 'CASCADE'],
  ['saved_vendors', 'vendor_id', 'vendors', 'vendor_id', 'CASCADE'],
  ['conversations', 'vendor_id', 'vendors', 'vendor_id', 'CASCADE'],

  // ── Owned by a parent record ─────────────────────────────────────────────
  ['budget_categories', 'budget_id', 'budgets', 'budget_id', 'CASCADE'],
  ['budget_custom_items', 'budget_id', 'budgets', 'budget_id', 'CASCADE'],
  ['expenses', 'budget_id', 'budgets', 'budget_id', 'CASCADE'],
  ['rsvp_responses', 'invitation_id', 'invitations', 'invitation_id', 'CASCADE'],
  ['messages', 'convo_id', 'conversations', 'convo_id', 'CASCADE'],

  // ── Shared history — never cascade ───────────────────────────────────────
  ['inquiries', 'vendor_id', 'vendors', 'vendor_id', 'RESTRICT'],
  ['inquiries', 'couple_user_id', 'users', 'user_id', 'RESTRICT'],
  ['vendor_feedback', 'vendor_id', 'vendors', 'vendor_id', 'RESTRICT'],
  ['vendor_feedback', 'couple_user_id', 'users', 'user_id', 'RESTRICT'],
];

const fkName = (child, column) => `fk_${child}_${column}`;

async function tableExists(sequelize, table) {
  const [rows] = await sequelize.query(
    `SELECT COUNT(*) n FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :table`,
    { replacements: { table } },
  );
  return rows[0].n > 0;
}

async function constraintExists(sequelize, name) {
  const [rows] = await sequelize.query(
    `SELECT COUNT(*) n FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA = DATABASE()
       AND CONSTRAINT_TYPE = 'FOREIGN KEY'
       AND CONSTRAINT_NAME = :name`,
    { replacements: { name } },
  );
  return rows[0].n > 0;
}

module.exports = {
  async up(queryInterface) {
    const sequelize = queryInterface.sequelize;

    // ── Clean up what the missing constraints already allowed ────────────
    for (let pass = 1; pass <= MAX_CLEANUP_PASSES; pass++) {
      let deletedThisPass = 0;

      for (const [child, column, parent, key] of FOREIGN_KEYS) {
        if (!(await tableExists(sequelize, child))) continue;
        if (!(await tableExists(sequelize, parent))) continue;

        const [orphans] = await sequelize.query(
          `SELECT ch.\`${column}\` AS ref, COUNT(*) AS n
           FROM \`${child}\` ch
           LEFT JOIN \`${parent}\` p ON ch.\`${column}\` = p.\`${key}\`
           WHERE ch.\`${column}\` IS NOT NULL AND p.\`${key}\` IS NULL
           GROUP BY ch.\`${column}\``,
        );
        if (orphans.length === 0) continue;

        // Logged rather than silent: these are real rows leaving the database.
        for (const row of orphans) {
          console.log(
            `  [004] ${child}: deleting ${row.n} row(s) referencing missing ${parent}.${key}=${row.ref}`,
          );
          deletedThisPass += Number(row.n);
        }
        await sequelize.query(
          `DELETE ch FROM \`${child}\` ch
           LEFT JOIN \`${parent}\` p ON ch.\`${column}\` = p.\`${key}\`
           WHERE ch.\`${column}\` IS NOT NULL AND p.\`${key}\` IS NULL`,
        );
      }

      if (deletedThisPass === 0) break;
      if (pass === MAX_CLEANUP_PASSES) {
        throw new Error(
          'Orphan cleanup did not reach a fixed point — a reference cycle, or deeper nesting than expected.',
        );
      }
    }

    // ── Add the constraints ──────────────────────────────────────────────
    for (const [child, column, parent, key, onDelete] of FOREIGN_KEYS) {
      if (!(await tableExists(sequelize, child))) continue;
      if (!(await tableExists(sequelize, parent))) continue;

      const name = fkName(child, column);
      if (await constraintExists(sequelize, name)) continue;

      await queryInterface.addConstraint(child, {
        fields: [column],
        type: 'foreign key',
        name,
        references: { table: parent, field: key },
        onDelete,
        onUpdate: 'CASCADE',
      });
    }
  },
};

/**
 * Moves vendor availability out of the `vendors.blocked_dates` JSON array and
 * into a `vendor_blocked_dates` table.
 *
 * ## Why
 *
 * A JSON array of dates in one column is a repeating group — a 1NF violation.
 * The practical cost was not tidiness: the database could not answer "which
 * vendors are free on 2026-09-12", so availability was filtered in the Flutter
 * client after downloading whole vendor pools. As rows with an index on the
 * date, that becomes a query.
 *
 * ## Safety
 *
 * Backfill, verify, then drop — and the verification throws rather than
 * proceeding if a single date fails to survive the move, because dropping the
 * column is the one irreversible step here. Re-running is safe: the table is
 * only created if absent, the backfill only runs while the old column still
 * exists, and the drop only happens once counts agree.
 */
module.exports = {
  async up(queryInterface, Sequelize, sequelize) {
    const db = sequelize || queryInterface.sequelize;

    // ── 1. The table ──────────────────────────────────────────────────────
    const tables = await queryInterface.showAllTables();
    const hasTable = tables
      .map((t) => (typeof t === 'string' ? t : t.tableName))
      .includes('vendor_blocked_dates');

    if (!hasTable) {
      await queryInterface.createTable('vendor_blocked_dates', {
        vendor_id: {
          type: Sequelize.UUID,
          allowNull: false,
          primaryKey: true,
          references: { model: 'vendors', key: 'vendor_id' },
          onDelete: 'CASCADE',
          onUpdate: 'CASCADE',
        },
        blocked_date: {
          type: Sequelize.DATEONLY,
          allowNull: false,
          primaryKey: true,
        },
      });
      await queryInterface.addIndex('vendor_blocked_dates', ['blocked_date'], {
        name: 'vendor_blocked_dates_date_idx',
      });
    }

    // ── 2. Backfill, while the old column is still there ──────────────────
    const vendorColumns = await queryInterface.describeTable('vendors');
    if (!vendorColumns.blocked_dates) return; // already migrated

    const [vendors] = await db.query(
      'SELECT vendor_id, blocked_dates FROM vendors WHERE blocked_dates IS NOT NULL',
    );

    let expected = 0;
    for (const row of vendors) {
      // MySQL's JSON type comes back parsed; a TEXT fallback would not.
      const raw = typeof row.blocked_dates === 'string'
        ? JSON.parse(row.blocked_dates || '[]')
        : row.blocked_dates || [];
      const dates = [...new Set(raw.map((d) => String(d).slice(0, 10)))]
        .filter((d) => /^\d{4}-\d{2}-\d{2}$/.test(d));
      if (dates.length === 0) continue;

      expected += dates.length;
      for (const date of dates) {
        await db.query(
          `INSERT IGNORE INTO vendor_blocked_dates (vendor_id, blocked_date)
           VALUES (:vendorId, :date)`,
          { replacements: { vendorId: row.vendor_id, date } },
        );
      }
    }

    // ── 3. Verify before the irreversible step ────────────────────────────
    const [[{ moved }]] = await db.query(
      'SELECT COUNT(*) AS moved FROM vendor_blocked_dates',
    );
    if (Number(moved) < expected) {
      throw new Error(
        `Backfill incomplete: expected at least ${expected} blocked dates, found ${moved}. `
        + 'Leaving vendors.blocked_dates in place — no data has been lost.',
      );
    }
    console.log(`  [005] moved ${expected} blocked date(s) into vendor_blocked_dates`);

    // ── 4. Drop the old column ────────────────────────────────────────────
    await queryInterface.removeColumn('vendors', 'blocked_dates');
  },
};

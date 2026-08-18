/**
 * Moves wedding-class packages out of the `vendors.packages` JSON array into
 * `vendor_packages` + `vendor_package_inclusions`.
 *
 * The last and worst of the schema's 1NF violations: an array of objects, each
 * carrying its own nested `inclusions` array — a repeating group inside a
 * repeating group, which is why it needs two tables rather than one.
 *
 * Backfill → verify → drop, with the verification counting both levels. The
 * drop is the only irreversible step, so it does not happen unless every
 * package and every inclusion is accounted for.
 */
module.exports = {
  async up(queryInterface, Sequelize, sequelize) {
    const db = sequelize || queryInterface.sequelize;

    const existing = (await queryInterface.showAllTables())
      .map((t) => (typeof t === 'string' ? t : t.tableName));

    // ── 1. Tables ─────────────────────────────────────────────────────────
    if (!existing.includes('vendor_packages')) {
      await queryInterface.createTable('vendor_packages', {
        package_id: { type: Sequelize.UUID, primaryKey: true },
        vendor_id: {
          type: Sequelize.UUID,
          allowNull: false,
          references: { model: 'vendors', key: 'vendor_id' },
          onDelete: 'CASCADE',
          onUpdate: 'CASCADE',
        },
        tier: { type: Sequelize.ENUM('luxury', 'starter'), allowNull: false },
        title: { type: Sequelize.STRING(200), allowNull: false },
        price: { type: Sequelize.DECIMAL(12, 2), allowNull: true },
        sort_order: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
      });
      await queryInterface.addIndex('vendor_packages', ['vendor_id'], {
        name: 'vendor_packages_vendor_id_idx',
      });
      await queryInterface.addIndex('vendor_packages', ['tier'], {
        name: 'vendor_packages_tier_idx',
      });
    }

    if (!existing.includes('vendor_package_inclusions')) {
      await queryInterface.createTable('vendor_package_inclusions', {
        package_id: {
          type: Sequelize.UUID,
          allowNull: false,
          primaryKey: true,
          references: { model: 'vendor_packages', key: 'package_id' },
          onDelete: 'CASCADE',
          onUpdate: 'CASCADE',
        },
        sort_order: { type: Sequelize.INTEGER, allowNull: false, primaryKey: true },
        description: { type: Sequelize.STRING(300), allowNull: false },
      });
    }

    // ── 2. Backfill ───────────────────────────────────────────────────────
    const vendorColumns = await queryInterface.describeTable('vendors');
    if (!vendorColumns.packages) return; // already migrated

    const [rows] = await db.query(
      'SELECT vendor_id, packages FROM vendors WHERE packages IS NOT NULL',
    );

    const { randomUUID } = require('crypto');
    let expectedPackages = 0;
    let expectedInclusions = 0;

    for (const row of rows) {
      const raw = typeof row.packages === 'string'
        ? JSON.parse(row.packages || '[]')
        : row.packages || [];
      if (!Array.isArray(raw) || raw.length === 0) continue;

      let order = 0;
      for (const pkg of raw) {
        if (!pkg || typeof pkg !== 'object') continue;
        // Anything that would violate the new NOT NULL / ENUM columns is
        // skipped rather than allowed to abort the whole migration — the JSON
        // column enforced none of this, so historic rows may be malformed.
        const tier = ['luxury', 'starter'].includes(pkg.tier) ? pkg.tier : null;
        const title = typeof pkg.title === 'string' ? pkg.title.trim().slice(0, 200) : '';
        if (!tier || !title) {
          console.log(`  [007] skipping malformed package on vendor ${row.vendor_id}`);
          continue;
        }

        const packageId = typeof pkg.package_id === 'string' && pkg.package_id
          ? pkg.package_id
          : randomUUID();
        const price = pkg.price == null || !Number.isFinite(Number(pkg.price))
          ? null
          : Number(pkg.price);

        await db.query(
          `INSERT IGNORE INTO vendor_packages
             (package_id, vendor_id, tier, title, price, sort_order)
           VALUES (:packageId, :vendorId, :tier, :title, :price, :sortOrder)`,
          {
            replacements: {
              packageId, vendorId: row.vendor_id, tier, title, price, sortOrder: order,
            },
          },
        );
        expectedPackages += 1;
        order += 1;

        const inclusions = Array.isArray(pkg.inclusions)
          ? pkg.inclusions
            .map((i) => (typeof i === 'string' ? i.trim().slice(0, 300) : ''))
            .filter(Boolean)
          : [];
        for (const [i, description] of inclusions.entries()) {
          await db.query(
            `INSERT IGNORE INTO vendor_package_inclusions
               (package_id, sort_order, description)
             VALUES (:packageId, :sortOrder, :description)`,
            { replacements: { packageId, sortOrder: i, description } },
          );
          expectedInclusions += 1;
        }
      }
    }

    // ── 3. Verify both levels ─────────────────────────────────────────────
    const [[{ movedPackages }]] = await db.query(
      'SELECT COUNT(*) AS movedPackages FROM vendor_packages',
    );
    const [[{ movedInclusions }]] = await db.query(
      'SELECT COUNT(*) AS movedInclusions FROM vendor_package_inclusions',
    );
    if (Number(movedPackages) < expectedPackages
        || Number(movedInclusions) < expectedInclusions) {
      throw new Error(
        `Backfill incomplete: expected ${expectedPackages} packages / `
        + `${expectedInclusions} inclusions, found ${movedPackages} / ${movedInclusions}. `
        + 'Leaving vendors.packages in place — no data has been lost.',
      );
    }
    console.log(
      `  [007] moved ${expectedPackages} package(s) and ${expectedInclusions} inclusion(s)`,
    );

    // ── 4. Drop ───────────────────────────────────────────────────────────
    await queryInterface.removeColumn('vendors', 'packages');
  },
};

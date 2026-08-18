/**
 * Moves style tags out of the `style_tags` JSON arrays on `vendors` and
 * `couple_profiles` into `vendor_style_tags` and `couple_style_tags`.
 *
 * Same repeating-group violation as blocked_dates, in two places, with the
 * same practical cost: "every vendor tagged Bohemian" was not a query the
 * database could answer, so style matching happens in the client against a
 * fully downloaded vendor pool.
 *
 * Backfill → verify → drop, and the verification throws rather than dropping
 * a column whose contents did not all survive.
 */

const SOURCES = [
  {
    table: 'vendors',
    ownerKey: 'vendor_id',
    target: 'vendor_style_tags',
    parent: 'vendors',
    parentKey: 'vendor_id',
    index: 'vendor_style_tags_tag_idx',
  },
  {
    table: 'couple_profiles',
    ownerKey: 'user_id',
    target: 'couple_style_tags',
    targetKey: 'couple_user_id',
    parent: 'users',
    parentKey: 'user_id',
    index: 'couple_style_tags_tag_idx',
  },
];

const MAX_TAG_LENGTH = 60;

module.exports = {
  async up(queryInterface, Sequelize, sequelize) {
    const db = sequelize || queryInterface.sequelize;

    const existing = (await queryInterface.showAllTables())
      .map((t) => (typeof t === 'string' ? t : t.tableName));

    for (const src of SOURCES) {
      const targetKey = src.targetKey || src.ownerKey;

      // ── 1. Table ────────────────────────────────────────────────────────
      if (!existing.includes(src.target)) {
        await queryInterface.createTable(src.target, {
          [targetKey]: {
            type: Sequelize.UUID,
            allowNull: false,
            primaryKey: true,
            references: { model: src.parent, key: src.parentKey },
            onDelete: 'CASCADE',
            onUpdate: 'CASCADE',
          },
          tag: {
            type: Sequelize.STRING(MAX_TAG_LENGTH),
            allowNull: false,
            primaryKey: true,
          },
        });
        await queryInterface.addIndex(src.target, ['tag'], { name: src.index });
      }

      // ── 2. Backfill while the column still exists ───────────────────────
      const columns = await queryInterface.describeTable(src.table);
      if (!columns.style_tags) continue; // already migrated

      const [rows] = await db.query(
        `SELECT \`${src.ownerKey}\` AS owner, style_tags FROM \`${src.table}\`
         WHERE style_tags IS NOT NULL`,
      );

      let expected = 0;
      for (const row of rows) {
        const raw = typeof row.style_tags === 'string'
          ? JSON.parse(row.style_tags || '[]')
          : row.style_tags || [];
        const tags = [...new Set(
          raw
            .filter((t) => typeof t === 'string')
            .map((t) => t.trim().slice(0, MAX_TAG_LENGTH))
            .filter(Boolean),
        )];
        if (tags.length === 0) continue;

        expected += tags.length;
        for (const tag of tags) {
          await db.query(
            `INSERT IGNORE INTO \`${src.target}\` (\`${targetKey}\`, tag)
             VALUES (:owner, :tag)`,
            { replacements: { owner: row.owner, tag } },
          );
        }
      }

      // ── 3. Verify before the irreversible step ──────────────────────────
      const [[{ moved }]] = await db.query(
        `SELECT COUNT(*) AS moved FROM \`${src.target}\``,
      );
      if (Number(moved) < expected) {
        throw new Error(
          `Backfill incomplete for ${src.table}: expected at least ${expected} tags, found ${moved}. `
          + `Leaving ${src.table}.style_tags in place — no data has been lost.`,
        );
      }
      console.log(`  [006] moved ${expected} tag(s) into ${src.target}`);

      // ── 4. Drop ─────────────────────────────────────────────────────────
      await queryInterface.removeColumn(src.table, 'style_tags');
    }
  },
};

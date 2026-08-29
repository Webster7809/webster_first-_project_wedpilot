/**
 * Adds `expenses.category_id`, backfills it from the existing
 * `(budget_id, category_name)` string match against `budget_categories`,
 * constrains it with a FK, then locks `budget_categories` down so
 * `(budget_id, category_name)` can never silently duplicate again.
 *
 * ## Why category_id at all
 *
 * Expense.category_name and BudgetCategory.category_name have only ever
 * been linked by a string-equality lookup done at request time
 * (`BudgetCategory.findOne({ where: { budget_id, category_name } })` in
 * POST/DELETE /expenses) — no FK, no shared id. There's no rename endpoint
 * today, so nothing has actually drifted, but nothing in the schema stopped
 * it either. category_id makes the relationship real; category_name stays
 * for display/back-compat.
 *
 * ## Backfill determinism
 *
 * A (budget_id, category_name) pair can currently match more than one
 * budget_categories row — nothing has ever stopped it (syncCategoriesForNewTotal
 * in routes/budget.js only dedupes at the application level). Where that
 * happens, the earliest-created row wins, ties broken by id — picked via a
 * NOT EXISTS self-join rather than a window function, since no other
 * migration in this codebase uses one and MySQL version isn't pinned
 * anywhere in this repo.
 *
 * ## onDelete: SET NULL
 *
 * No route deletes a BudgetCategory today. If one is added later, CASCADE
 * would delete a real expense/receipt record along with the category — the
 * money was still spent. RESTRICT would block that feature forever once a
 * category has one expense against it. SET NULL keeps the expense, drops
 * only the (already-optional) category link.
 *
 * ## Safety on the unique index
 *
 * The final step throws and stops, naming every offending pair, rather than
 * silently skipping or auto-merging duplicates — same "block until a human
 * resolves it" behaviour as 004/005/006/007. Every step before it is
 * check-before-create or backfill-is-idempotent, so a re-run after the
 * duplicates are fixed only has to redo that one step.
 */

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
  async up(queryInterface, Sequelize, sequelize) {
    // ── (a) Add the column ────────────────────────────────────────────────
    const expenseColumns = await queryInterface.describeTable('expenses');
    if (!expenseColumns.category_id) {
      await queryInterface.addColumn('expenses', 'category_id', {
        type: Sequelize.UUID,
        allowNull: true,
      });
    }

    // ── (b) Backfill ─────────────────────────────────────────────────────
    // Duplicates, logged before the backfill runs so the log explains why a
    // given expense ended up pointing at the row it did.
    const [dupeGroups] = await sequelize.query(`
      SELECT budget_id, category_name, COUNT(*) AS n
      FROM budget_categories
      GROUP BY budget_id, category_name
      HAVING COUNT(*) > 1
    `);
    for (const g of dupeGroups) {
      console.log(
        `  [018] duplicate budget_category: budget_id=${g.budget_id} `
        + `category_name="${g.category_name}" (${g.n} rows) — backfill uses `
        + 'the earliest-created row; see the unique-index step below for '
        + 'whether this still needs manual resolution.',
      );
    }

    // Single UPDATE...JOIN: for each expense, join to the one
    // budget_categories row for its (budget_id, category_name) with the
    // smallest (created_at, id) — the NOT EXISTS clause is "is there a row
    // that should sort before this one", how the earliest row is picked
    // without a window function. `WHERE e.category_id IS NULL` makes
    // re-running a no-op for already-backfilled rows; unmatched rows get the
    // same (deterministic) result on every re-run either way.
    await sequelize.query(`
      UPDATE expenses e
      JOIN (
        SELECT bc1.budget_id, bc1.category_name, bc1.id AS canonical_id
        FROM budget_categories bc1
        WHERE NOT EXISTS (
          SELECT 1 FROM budget_categories bc2
          WHERE bc2.budget_id = bc1.budget_id
            AND bc2.category_name = bc1.category_name
            AND (bc2.created_at < bc1.created_at
                 OR (bc2.created_at = bc1.created_at AND bc2.id < bc1.id))
        )
      ) canon
        ON canon.budget_id = e.budget_id AND canon.category_name = e.category_name
      SET e.category_id = canon.canonical_id
      WHERE e.category_id IS NULL
    `);

    // Logged, not silently ignored: an expense whose category_name no
    // longer matches any budget_categories row for its budget. No active
    // rename path exists today, so this should print nothing — if it does,
    // that's real pre-existing drift.
    const [unmatched] = await sequelize.query(`
      SELECT expense_id, budget_id, category_name
      FROM expenses
      WHERE category_id IS NULL
    `);
    for (const row of unmatched) {
      console.log(
        `  [018] no matching budget_category for expense ${row.expense_id} `
        + `(budget_id=${row.budget_id}, category_name="${row.category_name}") — `
        + 'left category_id NULL.',
      );
    }
    console.log(
      `  [018] backfill complete: ${unmatched.length} expense(s) unmatched, `
      + `${dupeGroups.length} duplicate budget_category pair(s) encountered.`,
    );

    // ── (c) FK on expenses.category_id ──────────────────────────────────
    if (!(await constraintExists(sequelize, 'fk_expenses_category_id'))) {
      await queryInterface.addConstraint('expenses', {
        fields: ['category_id'],
        type: 'foreign key',
        name: 'fk_expenses_category_id',
        references: { table: 'budget_categories', field: 'id' },
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
      });
    }

    // ── (d) Unique index — blocks on remaining duplicates ────────────────
    const bcIndexes = await queryInterface.showIndex('budget_categories');
    const uniqueIndexName = 'budget_categories_budget_category_unique';
    if (!bcIndexes.some((i) => i.name === uniqueIndexName)) {
      const [remainingDupes] = await sequelize.query(`
        SELECT budget_id, category_name, COUNT(*) AS n
        FROM budget_categories
        GROUP BY budget_id, category_name
        HAVING COUNT(*) > 1
      `);
      if (remainingDupes.length > 0) {
        const details = remainingDupes
          .map((d) => `budget_id=${d.budget_id} category_name="${d.category_name}" (${d.n} rows)`)
          .join('; ');
        throw new Error(
          'Cannot add unique index on budget_categories(budget_id, category_name): '
          + `${remainingDupes.length} duplicate pair(s) still exist: ${details}. `
          + 'Resolve by deleting or renaming the extra row(s) for each pair — '
          + 'the category_id backfill above already pointed every expense at '
          + 'the earliest-created row in each pair, so keep that one if in '
          + 'doubt — then re-run this migration.',
        );
      }
      await queryInterface.addIndex('budget_categories', ['budget_id', 'category_name'], {
        name: uniqueIndexName,
        unique: true,
      });
    }
  },
};

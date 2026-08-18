/**
 * Cleans up duplicate indexes and adds the missing ones on foreign-key and
 * filter columns.
 *
 * ## Why there are duplicates
 *
 * `sequelize.sync({ alter: true })` cannot match an existing unique index to
 * the one declared on the model, so every server restart added another copy.
 * A development database that had been restarted a few dozen times ended up
 * with 14 indexes on `users.email`, 16 on `invitations.share_token`, 10 on
 * `vendors.user_id` and 6 on `budgets.couple_user_id`.
 *
 * That is not cosmetic. MySQL caps a table at 64 indexes, so `invitations`
 * was on a path to refusing writes outright, and until then every INSERT and
 * UPDATE paid to maintain all sixteen copies. `alter` is now gated to
 * non-production (see server.js), but the damage it already did still has to
 * be swept up, and any developer machine will have it too.
 *
 * ## Why the additions
 *
 * `inquiries` carried nothing but its primary key, while the lead inbox, the
 * vendor dashboard, the double-booking conflict check and the AI matcher all
 * filter it by vendor_id / couple_user_id / status / wedding_date. Same story
 * for `notifications.user_id`, which the header's unread badge now reads on
 * every dashboard build. Those were full table scans.
 *
 * Both halves are idempotent: indexes are looked up before being dropped or
 * created, so re-running is a no-op.
 */

/// Kept per table: the canonical name each duplicate set collapses to.
const CANONICAL = {
  users: 'users_email_unique',
  invitations: 'invitations_share_token_unique',
  vendors: 'vendors_user_id_unique',
  budgets: 'budgets_couple_user_id_unique',
  couple_profiles: 'couple_profiles_user_id_unique',
  saved_vendors: 'saved_vendors_couple_vendor_unique',
};

/// Columns each canonical index covers, used to spot its duplicates.
const DUPLICATE_TARGETS = {
  users: ['email'],
  invitations: ['share_token'],
  vendors: ['user_id'],
  budgets: ['couple_user_id'],
  couple_profiles: ['user_id'],
  saved_vendors: ['couple_user_id', 'vendor_id'],
};

const ADDITIONS = [
  ['inquiries', ['vendor_id'], 'inquiries_vendor_id_idx'],
  ['inquiries', ['couple_user_id'], 'inquiries_couple_user_id_idx'],
  // The conflict check filters vendor + status + date together.
  ['inquiries', ['vendor_id', 'status', 'wedding_date'], 'inquiries_vendor_status_date_idx'],
  ['notifications', ['user_id', 'is_read'], 'notifications_user_read_idx'],
  ['messages', ['convo_id'], 'messages_convo_id_idx'],
  ['expenses', ['budget_id'], 'expenses_budget_id_idx'],
  ['budget_categories', ['budget_id'], 'budget_categories_budget_id_idx'],
  ['budget_custom_items', ['budget_id'], 'budget_custom_items_budget_id_idx'],
  ['tasks', ['couple_user_id'], 'tasks_couple_user_id_idx'],
  ['guests', ['couple_user_id'], 'guests_couple_user_id_idx'],
  ['rsvp_responses', ['invitation_id'], 'rsvp_responses_invitation_id_idx'],
  ['vendor_media', ['vendor_id'], 'vendor_media_vendor_id_idx'],
  ['vendor_feedback', ['vendor_id'], 'vendor_feedback_vendor_id_idx'],
];

async function indexesFor(queryInterface, table) {
  try {
    return await queryInterface.showIndex(table);
  } catch {
    return []; // table not in this database
  }
}

module.exports = {
  async up(queryInterface) {
    // ── Drop duplicates ───────────────────────────────────────────────────
    for (const [table, columns] of Object.entries(DUPLICATE_TARGETS)) {
      const keep = CANONICAL[table];
      const indexes = await indexesFor(queryInterface, table);

      for (const index of indexes) {
        if (index.primary || index.name === keep) continue;

        const fields = index.fields.map((f) => f.attribute);
        const sameColumns =
          fields.length === columns.length &&
          fields.every((f, i) => f === columns[i]);
        if (!sameColumns) continue;

        await queryInterface.removeIndex(table, index.name);
      }

      // Only after the duplicates are gone, in case the canonical one was
      // itself never created (a database built by sync alone may only have
      // the auto-named copies).
      const remaining = await indexesFor(queryInterface, table);
      if (!remaining.some((i) => i.name === keep)) {
        await queryInterface.addIndex(table, columns, {
          name: keep,
          unique: true,
        });
      }
    }

    // ── Add what was missing ──────────────────────────────────────────────
    for (const [table, columns, name] of ADDITIONS) {
      const indexes = await indexesFor(queryInterface, table);
      if (indexes.some((i) => i.name === name)) continue;
      await queryInterface.addIndex(table, columns, { name });
    }
  },
};

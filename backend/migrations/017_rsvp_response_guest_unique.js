/**
 * Two rounds of hardening for `rsvp_responses`, kept in one file since
 * neither has shipped yet.
 *
 * ## Part 1 — one response per guest (unique index)
 *
 * The app already assumed this 1:1 relationship everywhere (find-by-guest_id,
 * then update-or-create), but nothing stopped two near-simultaneous
 * submissions through the same personal invite link from both passing the
 * "no existing response yet" check and creating two rows — exactly the
 * "opened by two people" scenario the single-use lock in invitations.js's
 * POST /public/guest/:inviteToken/rsvp route is meant to prevent. Dedupes any
 * pre-existing duplicates first (keeping the most recent by
 * responded_at/created_at — the stale ones' rsvp_answers/rsvp_history rows
 * are cleaned up by their own existing CASCADE-on-rsvp_id constraints, see
 * migrations 015/016), then adds the unique index.
 *
 * ## Part 2 — foreign keys to guests and users
 *
 * `guest_id` and `couple_user_id` have never had a constraint, unlike every
 * other "owned by a user"/"owned by a parent record" column in this schema
 * (see 004_foreign_keys.js's FOREIGN_KEYS array — `guests.couple_user_id ->
 * users.user_id` and this table's own `invitation_id -> invitations` are
 * already CASCADE there). The gap is exactly what 004's docstring warns
 * about: cleanup is application-enforced — routes/guests.js's DELETE /:id
 * manually does `RsvpResponse.destroy({ where: { guest_id }})` before
 * `guest.destroy()`, one call site away from an orphan.
 *
 * Both CASCADE: a response means nothing once its guest or its couple is
 * gone, same reasoning as 004's "owned by a parent record" group this table
 * already belongs to via invitation_id.
 *
 * No fixed-point cleanup loop like 004's: rsvp_responses' own children
 * (rsvp_answers.rsvp_id, rsvp_history.rsvp_id) are already CASCADE, so
 * deleting an orphaned rsvp_responses row here cleans up under it
 * automatically at the DB level — there's no deeper chain to iterate.
 */

const FOREIGN_KEYS = [
  // child column, parent table, parent key, onDelete
  ['guest_id', 'guests', 'guest_id', 'CASCADE'],
  ['couple_user_id', 'users', 'user_id', 'CASCADE'],
];

const fkName = (column) => `fk_rsvp_responses_${column}`;

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
    // ── Part 1: dedupe + unique index on guest_id ──────────────────────────
    const indexes = await queryInterface.showIndex('rsvp_responses');
    if (!indexes.some((i) => i.name === 'rsvp_responses_guest_id_unique')) {
      const [duplicateGroups] = await sequelize.query(`
        SELECT guest_id FROM rsvp_responses GROUP BY guest_id HAVING COUNT(*) > 1
      `);
      for (const { guest_id: guestId } of duplicateGroups) {
        const [rows] = await sequelize.query(
          'SELECT rsvp_id FROM rsvp_responses WHERE guest_id = ? ORDER BY responded_at DESC, created_at DESC',
          { replacements: [guestId] },
        );
        const stale = rows.slice(1);
        for (const { rsvp_id: rsvpId } of stale) {
          await sequelize.query('DELETE FROM rsvp_responses WHERE rsvp_id = ?', { replacements: [rsvpId] });
        }
      }

      await queryInterface.addIndex('rsvp_responses', ['guest_id'], {
        name: 'rsvp_responses_guest_id_unique',
        unique: true,
      });
    }

    // ── Part 2: orphan cleanup, then FK constraints ────────────────────────
    for (const [column, parent, key] of FOREIGN_KEYS) {
      const [orphans] = await sequelize.query(
        `SELECT ch.\`${column}\` AS ref, COUNT(*) AS n
         FROM rsvp_responses ch
         LEFT JOIN \`${parent}\` p ON ch.\`${column}\` = p.\`${key}\`
         WHERE ch.\`${column}\` IS NOT NULL AND p.\`${key}\` IS NULL
         GROUP BY ch.\`${column}\``,
      );
      if (orphans.length > 0) {
        for (const row of orphans) {
          console.log(
            `  [017] rsvp_responses: deleting ${row.n} row(s) referencing missing ${parent}.${key}=${row.ref}`,
          );
        }
        await sequelize.query(
          `DELETE ch FROM rsvp_responses ch
           LEFT JOIN \`${parent}\` p ON ch.\`${column}\` = p.\`${key}\`
           WHERE ch.\`${column}\` IS NOT NULL AND p.\`${key}\` IS NULL`,
        );
      }
    }

    for (const [column, parent, key, onDelete] of FOREIGN_KEYS) {
      const name = fkName(column);
      if (await constraintExists(sequelize, name)) continue;
      await queryInterface.addConstraint('rsvp_responses', {
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

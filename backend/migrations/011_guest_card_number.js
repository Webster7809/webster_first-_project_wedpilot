/**
 * Adds `card_number`, `checked_in`, and `checked_in_at` to `guests`.
 *
 * A guest's personal invite link already locks after their first RSVP
 * response (see POST /public/guest/:inviteToken/rsvp), but that only stops
 * a *second* response through a forwarded link — it does nothing to stop
 * extra people showing up at the actual wedding on the strength of a
 * forwarded link or a screenshot of one. `card_number` is a short code the
 * couple can print or write on each guest's physical invitation; `checked_in`
 * / `checked_in_at` record the couple confirming, at the door, that the
 * number in front of them matches a real invited guest in their own list —
 * see POST /api/guests/checkin.
 *
 * Every existing guest is backfilled with a unique code too, not just ones
 * created after this migration — a couple mid-planning shouldn't have some
 * guests with cards and some without.
 *
 * A database created fresh by 001 already gets these from the model, so
 * each column is checked before being added, same as 002/008/009/010.
 */
function generateCardNumber() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

module.exports = {
  async up(queryInterface, Sequelize, sequelize) {
    const table = await queryInterface.describeTable('guests');

    if (!table.card_number) {
      await queryInterface.addColumn('guests', 'card_number', {
        type: Sequelize.STRING,
        allowNull: true,
      });
    }
    if (!table.checked_in) {
      await queryInterface.addColumn('guests', 'checked_in', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      });
    }
    if (!table.checked_in_at) {
      await queryInterface.addColumn('guests', 'checked_in_at', {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }

    const [rows] = await sequelize.query('SELECT guest_id FROM guests WHERE card_number IS NULL');
    for (const row of rows) {
      let code;
      let attempts = 0;
      // Collisions are extremely unlikely at 900k possible codes, but check
      // rather than assume — a duplicate card number defeats the whole point.
      do {
        code = generateCardNumber();
        attempts += 1;
        const [existing] = await sequelize.query(
          'SELECT 1 FROM guests WHERE card_number = ? LIMIT 1',
          { replacements: [code] },
        );
        if (existing.length === 0) break;
      } while (attempts < 10);
      await sequelize.query('UPDATE guests SET card_number = ? WHERE guest_id = ?', {
        replacements: [code, row.guest_id],
      });
    }

    const indexes = await queryInterface.showIndex('guests');
    if (!indexes.some((i) => i.name === 'guests_card_number_unique')) {
      await queryInterface.addIndex('guests', ['card_number'], {
        unique: true,
        name: 'guests_card_number_unique',
      });
    }
  },
};

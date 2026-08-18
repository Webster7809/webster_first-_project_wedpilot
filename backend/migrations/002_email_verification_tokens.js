/**
 * Adds the email-verification token columns to `users`.
 *
 * A database created fresh by 001 already has them (the model carries the
 * fields), so each column is checked before being added — that also makes a
 * partially-applied run safe to repeat.
 */
const COLUMNS = {
  verify_token_hash: { type: 'STRING', allowNull: true },
  verify_token_expires: { type: 'DATE', allowNull: true },
};

module.exports = {
  async up(queryInterface, Sequelize) {
    const table = await queryInterface.describeTable('users');
    for (const [name, spec] of Object.entries(COLUMNS)) {
      if (table[name]) continue;
      await queryInterface.addColumn('users', name, {
        type: Sequelize[spec.type],
        allowNull: spec.allowNull,
      });
    }
  },
};

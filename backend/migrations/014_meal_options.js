/**
 * Adds `meal_options` — the couple-configurable list of meal choices shown
 * on the public RSVP form (replacing free text there; see invitations.js).
 * `RsvpResponse.meal_preference` deliberately stays free text at the DB
 * layer with no FK to this table — editing/removing an option later must
 * never break an existing guest's already-recorded answer.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();
    if (tables.includes('meal_options')) return;

    await queryInterface.createTable('meal_options', {
      option_id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      invitation_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'invitations', key: 'invitation_id' },
        onDelete: 'CASCADE',
      },
      label: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      sort_order: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
      },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    });

    await queryInterface.addIndex('meal_options', ['invitation_id'], {
      name: 'meal_options_invitation_id_idx',
    });
  },
};

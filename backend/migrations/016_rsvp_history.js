/**
 * Adds `rsvp_history` — one row per couple-initiated edit to an RSVP (manual
 * entry from the guest list, or a status correction from the dashboard).
 * Guest self-edits through the public/personal links are NOT logged here —
 * this is a record of staff intervention, not a full audit of every change,
 * so it CASCADEs with its RSVP rather than preserving orphaned history.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();
    if (tables.includes('rsvp_history')) return;

    await queryInterface.createTable('rsvp_history', {
      history_id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      rsvp_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'rsvp_responses', key: 'rsvp_id' },
        onDelete: 'CASCADE',
      },
      changed_by_user_id: {
        type: Sequelize.UUID,
        allowNull: false,
      },
      previous_status: { type: Sequelize.STRING, allowNull: true },
      new_status: { type: Sequelize.STRING, allowNull: false },
      previous_guest_count: { type: Sequelize.INTEGER, allowNull: true },
      new_guest_count: { type: Sequelize.INTEGER, allowNull: false },
      changed_at: { type: Sequelize.DATE, allowNull: false },
    });

    await queryInterface.addIndex('rsvp_history', ['rsvp_id'], {
      name: 'rsvp_history_rsvp_id_idx',
    });
  },
};

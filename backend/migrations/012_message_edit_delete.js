/**
 * Adds `is_deleted` and `edited_at` to `messages`, so a sender can edit or
 * delete something they sent — mirroring WhatsApp: deleting replaces the
 * content with a tombstone both participants see (never a hard row delete,
 * which would silently break message ordering/timestamps for the other
 * side), and editing keeps the original `created_at` but stamps `edited_at`
 * so the UI can show "(edited)".
 *
 * A database created fresh by 001 already gets these from the model, so each
 * column is checked before being added, same as every migration since 002.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const table = await queryInterface.describeTable('messages');

    if (!table.is_deleted) {
      await queryInterface.addColumn('messages', 'is_deleted', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      });
    }
    if (!table.edited_at) {
      await queryInterface.addColumn('messages', 'edited_at', {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }
  },
};

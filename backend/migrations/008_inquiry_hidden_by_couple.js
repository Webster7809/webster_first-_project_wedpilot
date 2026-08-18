/**
 * Adds `hidden_by_couple` to `inquiries`.
 *
 * Lets a couple remove a closed-out request (declined or cancelled) from
 * their own "My Bookings" list without deleting the row itself — the vendor
 * side still needs it for their own history and for `recalculateVendorStats`,
 * and the notification a cancel/decline fires (`entity_id`/`entity_type`
 * pointing at this inquiry) would otherwise dangle. A database created fresh
 * by 001 already gets this from the model, so the column is checked before
 * being added, same as 002.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const table = await queryInterface.describeTable('inquiries');
    if (table.hidden_by_couple) return;
    await queryInterface.addColumn('inquiries', 'hidden_by_couple', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });
  },
};

/**
 * Adds `max_party_size` to `guests` — the upper bound on how many people a
 * single invitation covers ("the Banda family, max 4"), enforced against
 * `guestCount` on every RSVP submission (see guests.js POST /:id/rsvp and
 * invitations.js's two public RSVP routes).
 *
 * Left null for every pre-existing guest rather than backfilled to 1: null
 * means "uncapped," so no guest already invited before this shipped is
 * silently capped to a number nobody actually set. Only guests added or
 * edited after this migration get an explicit cap from the app layer.
 *
 * A database created fresh by 001 already gets this from the model, so the
 * column is checked before being added, same as 002/008/009/010/011.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const table = await queryInterface.describeTable('guests');

    if (!table.max_party_size) {
      await queryInterface.addColumn('guests', 'max_party_size', {
        type: Sequelize.INTEGER,
        allowNull: true,
      });
    }
  },
};

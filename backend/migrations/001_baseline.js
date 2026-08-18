/**
 * Baseline: create every table that doesn't exist yet.
 *
 * Until now the schema was produced by `sequelize.sync({ alter: true })` on
 * boot, so existing databases already have these tables. `sync()` without
 * `alter` only issues CREATE TABLE IF NOT EXISTS — it never modifies or drops
 * an existing table — which makes this safe to run against both a live
 * database (no-op) and an empty one (full schema).
 *
 * From here on, every schema change gets its own numbered migration. Do not
 * add `alter` to this file.
 */
module.exports = {
  async up(queryInterface, Sequelize, sequelize) {
    // Registers every model on the shared instance so sync() knows about them.
    require('../db/models/user');
    require('../db/models/coupleProfile');
    require('../db/models/task');
    require('../db/models/vendor');
    require('../db/models/vendorService');
    require('../db/models/vendorMedia');
    require('../db/models/vendorFeedback');
    require('../db/models/vendorStats');
    require('../db/models/inquiry');
    require('../db/models/savedVendor');
    require('../db/models/budget');
    require('../db/models/budgetCategory');
    require('../db/models/budgetCustomItem');
    require('../db/models/expense');
    require('../db/models/guest');
    require('../db/models/invitation');
    require('../db/models/rsvpResponse');
    require('../db/models/conversation');
    require('../db/models/message');
    require('../db/models/notification');
    require('../db/models/vendorMatch');

    await sequelize.sync();
  },
};

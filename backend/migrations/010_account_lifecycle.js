/**
 * Adds `email_notifications` and `deleted_at` to `users`.
 *
 * `email_notifications` backs the Settings screen's Email Notifications
 * toggle, which previously only wrote to a local Hive box on the client and
 * never reached the server — nothing could actually skip sending mail for a
 * user who opted out. Defaults true so existing users keep getting mail they
 * never explicitly muted.
 *
 * `deleted_at` distinguishes a self-service account deletion from an
 * admin-issued suspension. Both flip `is_suspended` (reusing the login-block
 * check already in verifyJwt/login/refresh), but only a deletion also scrubs
 * PII and sets this timestamp — see POST /api/auth/delete-account. A real
 * DELETE FROM users is not viable here: migration 004 makes `inquiries` and
 * `vendor_feedback` RESTRICT (not CASCADE) specifically so one party's
 * deletion can't erase the other party's booking history, so any account
 * with a booking or feedback on record would throw a FK violation instead.
 *
 * A database created fresh by 001 already gets both from the model, so each
 * column is checked before being added, same as 002/008/009.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const table = await queryInterface.describeTable('users');
    if (!table.email_notifications) {
      await queryInterface.addColumn('users', 'email_notifications', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      });
    }
    if (!table.deleted_at) {
      await queryInterface.addColumn('users', 'deleted_at', {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }
  },
};

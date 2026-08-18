/**
 * Adds `phone` to `users`.
 *
 * Both couple and vendor registration already collect a phone number (it's a
 * required field on the register form) and then silently discard it — never
 * sent past the client, nowhere on this model to hold it if it were. That
 * meant a vendor who typed their number at signup was asked to type the exact
 * same number again on the very next screen (onboarding's contact step), with
 * no way for the app to know it had already been given. This column, plus
 * threading `phone` through /register and back out via serializeUser, is what
 * lets onboarding prefill it instead of re-asking.
 *
 * A database created fresh by 001 already gets this from the model, so the
 * column is checked before being added, same as 002/008.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const table = await queryInterface.describeTable('users');
    if (table.phone) return;
    await queryInterface.addColumn('users', 'phone', {
      type: Sequelize.STRING,
      allowNull: true,
    });
  },
};

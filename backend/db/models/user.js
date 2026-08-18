const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const User = sequelize.define('User', {
  user_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: { isEmail: true },
  },
  password_hash: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  avatar_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  // Collected once at registration (both couple and vendor signup require
  // it) so it never has to be typed again — a vendor's onboarding contact
  // step and a couple's profile both prefill from this instead of re-asking.
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  role: {
    type: DataTypes.ENUM('couple', 'vendor', 'admin'),
    allowNull: false,
    defaultValue: 'couple',
  },
  is_verified: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  is_suspended: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  // SHA-256 hash of the current password-reset token (never the raw token,
  // same principle as password_hash — a DB leak shouldn't hand out usable
  // reset credentials). Null when no reset is in flight.
  reset_token_hash: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  reset_token_expires: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  // SHA-256 hash of the current email-verification token, same reasoning as
  // reset_token_hash above. Null once the address is verified, or before the
  // first verification email goes out.
  verify_token_hash: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  verify_token_expires: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  email_notifications: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  // Set only by POST /api/auth/delete-account, alongside is_suspended=true —
  // see migration 010 for why this is a scrub-and-flag rather than a real row
  // delete.
  deleted_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'users',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  // Named explicitly so repeated `sync({ alter: true })` runs recognize this
  // index as already present instead of adding a new one each time (the
  // inline `unique: true` shorthand doesn't get diffed correctly by
  // Sequelize's MySQL dialect and silently piles up duplicates over time —
  // this table alone had accumulated 63 duplicate `email` indexes before
  // hitting MySQL's 64-key-per-table ceiling).
  indexes: [{ unique: true, fields: ['email'], name: 'users_email_unique' }],
});

module.exports = User;

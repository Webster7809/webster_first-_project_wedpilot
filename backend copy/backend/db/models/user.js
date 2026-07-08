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

const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const CoupleProfile = sequelize.define('CoupleProfile', {
  profile_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  partner_user_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  wedding_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  location: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  guest_count: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  style_tags: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: [],
  },
  total_budget: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: true,
  },
  currency: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'ZMW',
  },
  partner_name: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  photo_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'couple_profiles',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  // Named explicitly so repeated `sync({ alter: true })` runs recognize this
  // index as already present instead of adding a new one each time (the
  // inline `unique: true` shorthand doesn't get diffed correctly by
  // Sequelize's MySQL dialect and silently piles up duplicates over time).
  indexes: [{ unique: true, fields: ['user_id'], name: 'couple_profiles_user_id_unique' }],
});

module.exports = CoupleProfile;

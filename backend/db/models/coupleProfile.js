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
    unique: true,
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
});

module.exports = CoupleProfile;

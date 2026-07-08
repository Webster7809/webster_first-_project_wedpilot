const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Vendor = sequelize.define('Vendor', {
  vendor_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  business_name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  category: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  location: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  latitude: {
    type: DataTypes.DOUBLE,
    allowNull: true,
  },
  longitude: {
    type: DataTypes.DOUBLE,
    allowNull: true,
  },
  tier: {
    type: DataTypes.ENUM('free', 'pro', 'premium'),
    allowNull: false,
    defaultValue: 'free',
  },
  verification_status: {
    type: DataTypes.ENUM('pending', 'verified', 'rejected'),
    allowNull: false,
    defaultValue: 'pending',
  },
  verification_note: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  is_featured: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  style_tags: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: [],
  },
  logo_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  website: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  whatsapp: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  contact_email: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  address: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  instagram_handle: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  blocked_dates: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: [],
  },
  is_custom_entry: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
}, {
  tableName: 'vendors',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  // Named explicitly — see couple_profiles.js for why (avoids Sequelize
  // piling up duplicate unique indexes on every alter-sync).
  indexes: [{ unique: true, fields: ['user_id'], name: 'vendors_user_id_unique' }],
});

module.exports = Vendor;

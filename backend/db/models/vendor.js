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
  // Wedding-class packages the vendor registers themselves:
  // [{ package_id, tier: 'luxury'|'starter', title, inclusions: [..], price }]
  packages: {
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
  // piling up duplicate indexes on every alter-sync). category and
  // verification_status are indexed because GET /api/vendors and the
  // AI-matching candidate fetch both filter on them directly (see
  // routes/vendors.js) — every vendor-match run does at least one such
  // query per requested category, so an unindexed scan there is on the hot
  // path for every "Create plan" tap, not just occasional admin queries.
  indexes: [
    { unique: true, fields: ['user_id'], name: 'vendors_user_id_unique' },
    { fields: ['category'], name: 'vendors_category_idx' },
    { fields: ['verification_status'], name: 'vendors_verification_status_idx' },
  ],
});

module.exports = Vendor;

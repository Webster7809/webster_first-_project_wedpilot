const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const VendorMedia = sequelize.define('VendorMedia', {
  media_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM('image', 'video'),
    allowNull: false,
    defaultValue: 'image',
  },
  url: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  thumbnail_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  is_featured: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  // No report/flag-content UI exists yet for couples or vendors to flag a
  // photo — so this queue is real but will legitimately stay empty until
  // that reporting entry point is built.
  status: {
    type: DataTypes.ENUM('active', 'flagged', 'removed'),
    allowNull: false,
    defaultValue: 'active',
  },
  flag_reason: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'vendor_media',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = VendorMedia;

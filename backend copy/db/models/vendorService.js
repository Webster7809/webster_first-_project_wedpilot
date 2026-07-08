const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const VendorService = sequelize.define('VendorService', {
  service_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  price_min: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  price_max: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  unit: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'package',
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
}, {
  tableName: 'vendor_services',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = VendorService;

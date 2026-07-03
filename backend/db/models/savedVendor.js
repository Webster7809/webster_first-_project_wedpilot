const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const SavedVendor = sequelize.define('SavedVendor', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
}, {
  tableName: 'saved_vendors',
  createdAt: 'created_at',
  updatedAt: false,
  indexes: [
    { unique: true, fields: ['couple_user_id', 'vendor_id'] },
  ],
});

module.exports = SavedVendor;

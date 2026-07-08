const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// One row per (couple, category) — holds whichever vendor is currently the
// AI matcher's top pick, so a repeat computation that lands on the same
// vendor can be told apart from an actual new match.
const VendorMatch = sequelize.define('VendorMatch', {
  match_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  category: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  confidence: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
}, {
  tableName: 'vendor_matches',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [{ unique: true, fields: ['couple_user_id', 'category'], name: 'vendor_matches_couple_category_unique' }],
});

module.exports = VendorMatch;

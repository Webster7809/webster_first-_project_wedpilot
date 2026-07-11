const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// The public-facing aggregate — this table (not vendor_feedback) is what the
// vendor directory/profile endpoints actually serve to couples browsing
// vendors. Recomputed by services/vendorStats.js whenever an event that
// should move the score occurs, rather than live-aggregated on every read.
const VendorStats = sequelize.define('VendorStats', {
  vendor_id: {
    type: DataTypes.UUID,
    primaryKey: true,
  },
  avg_star_rating: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  feedback_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  completed_weddings_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  avg_response_time_minutes: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  booking_acceptance_rate: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  on_time_rate: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  repeat_customer_rate: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  recommend_rate: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  is_verified_business: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  crs_score: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 0,
  },
  last_calculated_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'vendor_stats',
  timestamps: false,
});

module.exports = VendorStats;

const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// Private by design — a couple's star_rating and comment are never surfaced
// to other couples. Only the vendor who owns it and admins can read a row
// (enforced in routes/vendors.js and routes/admin.js, not just hidden in the
// UI). Only aggregate stats derived from this table (see vendorStats.js) are
// ever public.
const VendorFeedback = sequelize.define('VendorFeedback', {
  feedback_id: {
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
  // The specific booked inquiry that made this couple eligible to submit —
  // kept for traceability even though eligibility today is one-per-vendor.
  inquiry_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  star_rating: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: { min: 1, max: 5 },
  },
  comment: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  on_time: {
    type: DataTypes.ENUM('yes', 'no', 'not_applicable'),
    allowNull: true,
  },
  is_flagged: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  flag_reason: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'vendor_feedback',
  createdAt: 'created_at',
  updatedAt: false,
  // One feedback submission per couple-vendor pair, enforced at the DB layer
  // — named explicitly so repeated sync({ alter: true }) runs recognize it
  // instead of piling up duplicate indexes (see user.js for why that matters).
  indexes: [
    { unique: true, fields: ['couple_user_id', 'vendor_id'], name: 'vendor_feedback_couple_vendor_unique' },
  ],
});

module.exports = VendorFeedback;

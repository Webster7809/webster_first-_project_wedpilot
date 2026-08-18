const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

/**
 * One row per date a vendor is unavailable.
 *
 * Replaces the `vendors.blocked_dates` JSON array, which was a repeating group
 * in a single column — a 1NF violation, and the reason availability could only
 * ever be filtered in the client after fetching every vendor. As rows, the
 * database can answer "who is free on this date" directly.
 *
 * The composite primary key is the uniqueness rule: a vendor cannot block the
 * same day twice, which the old Set-in-JavaScript juggling had to enforce by
 * hand at every call site.
 */
const VendorBlockedDate = sequelize.define('VendorBlockedDate', {
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
    primaryKey: true,
  },
  blocked_date: {
    type: DataTypes.DATEONLY,
    allowNull: false,
    primaryKey: true,
  },
}, {
  tableName: 'vendor_blocked_dates',
  timestamps: false,
  indexes: [
    // The lookup that matters: every vendor free on a given wedding day.
    { fields: ['blocked_date'], name: 'vendor_blocked_dates_date_idx' },
  ],
});

module.exports = VendorBlockedDate;

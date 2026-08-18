const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Inquiry = sequelize.define('Inquiry', {
  inquiry_id: {
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
  status: {
    type: DataTypes.ENUM('newInquiry', 'viewed', 'responded', 'quoted', 'booked', 'declined', 'cancelled'),
    allowNull: false,
    defaultValue: 'newInquiry',
  },
  budget_range_min: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: true,
  },
  budget_range_max: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: true,
  },
  wedding_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  responded_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  decline_reason: {
    type: DataTypes.STRING(300),
    allowNull: true,
  },
  service_done_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  rating_reminder_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  rating_reminder_last_sent_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  // Removes a closed-out request from the couple's own "My Bookings" list
  // without deleting the row — the vendor side still needs it for their own
  // history and for recalculateVendorStats. See migrations/008.
  hidden_by_couple: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
}, {
  tableName: 'inquiries',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Inquiry;

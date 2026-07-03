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
    type: DataTypes.ENUM('newInquiry', 'viewed', 'responded', 'quoted', 'booked', 'declined'),
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
}, {
  tableName: 'inquiries',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Inquiry;

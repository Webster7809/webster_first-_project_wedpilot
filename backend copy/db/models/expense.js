const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Expense = sequelize.define('Expense', {
  expense_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  budget_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  category_name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  vendor_name: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  amount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  description: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  receipt_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  status: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'paid',
  },
}, {
  tableName: 'expenses',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Expense;

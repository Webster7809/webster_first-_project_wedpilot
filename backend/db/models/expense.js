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
  // Nullable: backfilled by migration 018 from the (budget_id,
  // category_name) match against BudgetCategory at the time it ran; new
  // rows get it set directly in POST /expenses (routes/budget.js).
  // category_name is kept alongside it for display/back-compat — the
  // Flutter client still only sends category_name, category_id is derived
  // server-side.
  category_id: {
    type: DataTypes.UUID,
    allowNull: true,
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

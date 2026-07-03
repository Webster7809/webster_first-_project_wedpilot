const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Budget = sequelize.define('Budget', {
  budget_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true,
  },
  total_amount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  currency: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'ZMW',
  },
  is_ai_generated: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
}, {
  tableName: 'budgets',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Budget;

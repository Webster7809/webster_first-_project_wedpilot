const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const BudgetCategory = sequelize.define('BudgetCategory', {
  id: {
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
  category_icon: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: '💰',
  },
  allocated_amount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  spent_amount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
    defaultValue: 0,
  },
  // Static rationale copy, never claim it's AI-generated — see constants/budgetTemplate.js.
  ai_justification: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'budget_categories',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = BudgetCategory;

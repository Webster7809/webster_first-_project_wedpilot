const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const BudgetCustomItem = sequelize.define('BudgetCustomItem', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  budget_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  amount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
}, {
  tableName: 'budget_custom_items',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = BudgetCustomItem;

const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Task = sequelize.define('Task', {
  task_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  phase: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  task: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  is_completed: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  due_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  linked_vendor_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  linked_vendor_name: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'tasks',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Task;

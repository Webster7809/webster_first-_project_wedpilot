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
  // The vendor's current business_name is looked up via this id at
  // serialization time (see routes/tasks.js) rather than stored here — a
  // stored copy would be a transitive dependency (name depends on the
  // vendor, not directly on the task) that could go stale after a rename.
  linked_vendor_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
}, {
  tableName: 'tasks',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Task;

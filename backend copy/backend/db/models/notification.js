const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Notification = sequelize.define('Notification', {
  notif_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  type: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  body: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  entity_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  entity_type: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
}, {
  tableName: 'notifications',
  createdAt: 'sent_at',
  updatedAt: false,
});

module.exports = Notification;

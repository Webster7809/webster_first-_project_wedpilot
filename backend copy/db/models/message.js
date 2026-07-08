const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// sender_name / sender_avatar_url are intentionally not columns here — the
// sender is always identifiable via sender_user_id, and their current
// name/avatar are looked up from users at serialization time (same approach
// already used for couple_name/vendor_name in inquiries.js), so a rename
// doesn't leave every past message with a stale display name.
const Message = sequelize.define('Message', {
  message_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  convo_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  sender_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM('text', 'image', 'file'),
    allowNull: false,
    defaultValue: 'text',
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
}, {
  tableName: 'messages',
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = Message;

const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// Deliberately holds only the couple/vendor pairing — no last_message_text,
// last_message_at, or unread_count columns. Those are all derivable from the
// messages table (a transitive dependency on data owned elsewhere), so they
// are computed at query time in routes/messaging.js instead of duplicated
// here where they could drift out of sync.
const Conversation = sequelize.define('Conversation', {
  convo_id: {
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
}, {
  tableName: 'conversations',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    { unique: true, fields: ['couple_user_id', 'vendor_id'], name: 'conversations_couple_vendor_unique' },
  ],
});

module.exports = Conversation;

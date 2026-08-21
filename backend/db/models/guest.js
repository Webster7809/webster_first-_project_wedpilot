const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Guest = sequelize.define('Guest', {
  guest_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  whatsapp_number: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  relation: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  is_invited: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  invite_token: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  invite_invitation_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  card_number: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  checked_in: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  checked_in_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'guests',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    { unique: true, fields: ['invite_token'], name: 'guests_invite_token_unique' },
    { unique: true, fields: ['card_number'], name: 'guests_card_number_unique' },
  ],
});

module.exports = Guest;

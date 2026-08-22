const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// One couple-initiated edit to an RSVP — see migrations/016_rsvp_history.js.
// Guest self-edits are never logged here, only staff (couple) intervention.
const RsvpHistory = sequelize.define('RsvpHistory', {
  history_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  rsvp_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  changed_by_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  previous_status: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  new_status: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  previous_guest_count: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  new_guest_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  changed_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
}, {
  tableName: 'rsvp_history',
  timestamps: false,
  indexes: [
    { fields: ['rsvp_id'], name: 'rsvp_history_rsvp_id_idx' },
  ],
});

module.exports = RsvpHistory;

const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const RsvpResponse = sequelize.define('RsvpResponse', {
  rsvp_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  // Nullable: a guest can be added to the couple's list and RSVP'd for
  // manually before an invitation card has even been designed.
  invitation_id: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  // Every RSVP is recorded against a real Guest row (both the manual
  // guest-list flow and the public share-link flow find-or-create one), so
  // guest_name is looked up via this id at serialization time rather than
  // duplicated here — a stored copy would go stale if the guest is later
  // renamed via editGuest().
  guest_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  attending: {
    type: DataTypes.ENUM('yes', 'no', 'maybe'),
    allowNull: false,
  },
  guest_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
  },
  meal_preference: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  dietary_notes: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  // Managed manually (set on both create and status-update) rather than via
  // Sequelize's createdAt option, since re-responding should bump it too.
  responded_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
}, {
  tableName: 'rsvp_responses',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = RsvpResponse;

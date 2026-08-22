const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// Couple-configurable meal choices shown on the public RSVP form (see
// migrations/014_meal_options.js). Deliberately no relation back to
// RsvpResponse.meal_preference, which stores free text — removing an option
// here must never touch a guest's already-recorded answer.
const MealOption = sequelize.define('MealOption', {
  option_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  invitation_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  label: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'meal_options',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    { fields: ['invitation_id'], name: 'meal_options_invitation_id_idx' },
  ],
});

module.exports = MealOption;

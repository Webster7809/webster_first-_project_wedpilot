const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// Couple-configurable custom RSVP question, scoped to one invitation (see
// migrations/015_rsvp_questions.js). `type` is a plain validated string
// (yes_no/single_choice/multi_choice/short_text/long_text/number) rather
// than a DB enum — see the route layer for the allowed set.
const RsvpQuestion = sequelize.define('RsvpQuestion', {
  question_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  invitation_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  question_text: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  type: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  // Choice labels for single_choice/multi_choice; null for other types.
  options: {
    type: DataTypes.JSON,
    allowNull: true,
  },
  is_required: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  is_enabled: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'rsvp_questions',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    { fields: ['invitation_id'], name: 'rsvp_questions_invitation_id_idx' },
  ],
});

module.exports = RsvpQuestion;

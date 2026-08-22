const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// One guest's answer to one custom RSVP question (see
// migrations/015_rsvp_questions.js). answer_text covers
// short_text/long_text/single_choice/yes_no/number; answer_json (a string
// array) covers multi_choice only.
const RsvpAnswer = sequelize.define('RsvpAnswer', {
  answer_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  rsvp_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  question_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  answer_text: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  answer_json: {
    type: DataTypes.JSON,
    allowNull: true,
  },
}, {
  tableName: 'rsvp_answers',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    { fields: ['rsvp_id'], name: 'rsvp_answers_rsvp_id_idx' },
    { fields: ['question_id'], name: 'rsvp_answers_question_id_idx' },
  ],
});

module.exports = RsvpAnswer;

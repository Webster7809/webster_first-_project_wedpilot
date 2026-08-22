/**
 * Adds `rsvp_questions` (couple-configurable custom questions per invitation
 * — "Do you need transportation?", "Which event will you attend?") and
 * `rsvp_answers` (one guest's answer to one question).
 *
 * `rsvp_answers.question_id` is RESTRICT, not CASCADE: deleting a question a
 * guest has already answered would silently erase their answer, so the
 * couple can only disable it (`is_enabled = false`) once it has any answers
 * — see the 409 in invitations.js's DELETE /questions/:id.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();

    if (!tables.includes('rsvp_questions')) {
      await queryInterface.createTable('rsvp_questions', {
        question_id: {
          type: Sequelize.UUID,
          defaultValue: Sequelize.UUIDV4,
          primaryKey: true,
        },
        invitation_id: {
          type: Sequelize.UUID,
          allowNull: false,
          references: { model: 'invitations', key: 'invitation_id' },
          onDelete: 'CASCADE',
        },
        question_text: { type: Sequelize.STRING, allowNull: false },
        // Plain validated string, not an ENUM — this set is the kind that
        // grows, and an ENUM would need a table-rewrite migration to add one.
        type: { type: Sequelize.STRING, allowNull: false },
        options: { type: Sequelize.JSON, allowNull: true },
        is_required: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        is_enabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sort_order: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        created_at: { type: Sequelize.DATE, allowNull: false },
        updated_at: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('rsvp_questions', ['invitation_id'], {
        name: 'rsvp_questions_invitation_id_idx',
      });
    }

    if (!tables.includes('rsvp_answers')) {
      await queryInterface.createTable('rsvp_answers', {
        answer_id: {
          type: Sequelize.UUID,
          defaultValue: Sequelize.UUIDV4,
          primaryKey: true,
        },
        rsvp_id: {
          type: Sequelize.UUID,
          allowNull: false,
          references: { model: 'rsvp_responses', key: 'rsvp_id' },
          onDelete: 'CASCADE',
        },
        question_id: {
          type: Sequelize.UUID,
          allowNull: false,
          references: { model: 'rsvp_questions', key: 'question_id' },
          onDelete: 'RESTRICT',
        },
        // short_text/long_text/single_choice/yes_no/number.
        answer_text: { type: Sequelize.TEXT, allowNull: true },
        // multi_choice only.
        answer_json: { type: Sequelize.JSON, allowNull: true },
        created_at: { type: Sequelize.DATE, allowNull: false },
        updated_at: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('rsvp_answers', ['rsvp_id'], {
        name: 'rsvp_answers_rsvp_id_idx',
      });
      await queryInterface.addIndex('rsvp_answers', ['question_id'], {
        name: 'rsvp_answers_question_id_idx',
      });
    }
  },
};

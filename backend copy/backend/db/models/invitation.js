const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const Invitation = sequelize.define('Invitation', {
  invitation_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  template_id: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  custom_data: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: {},
  },
  share_token: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('draft', 'published', 'archived'),
    allowNull: false,
    defaultValue: 'draft',
  },
  view_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'invitations',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  // Named explicitly — see couple_profiles.js for why (avoids Sequelize
  // piling up duplicate unique indexes on every alter-sync).
  indexes: [{ unique: true, fields: ['share_token'], name: 'invitations_share_token_unique' }],
});

module.exports = Invitation;

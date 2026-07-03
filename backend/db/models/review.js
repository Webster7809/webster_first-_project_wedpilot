const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

// status defaults to 'approved' — there is no admin moderation UI yet
// (planned for a later phase), so leaving reviews 'pending' by default would
// make every review permanently invisible. This is a deliberate scope
// decision, not an oversight.
const Review = sequelize.define('Review', {
  review_id: {
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
  rating: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: { min: 1, max: 5 },
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  body: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected', 'flagged'),
    allowNull: false,
    defaultValue: 'approved',
  },
  photo_urls: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: [],
  },
  published_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'reviews',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Review;

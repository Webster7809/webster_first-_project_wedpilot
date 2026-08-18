const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

/**
 * Style tags as rows, replacing the `style_tags` JSON arrays that were on both
 * `vendors` and `couple_profiles` — the same repeating-group 1NF violation in
 * two places.
 *
 * Two tables rather than one polymorphic `style_tags(owner_type, owner_id)`:
 * a polymorphic owner column cannot carry a foreign key, and giving up
 * referential integrity to save a table is the wrong trade in a schema that
 * just spent a migration acquiring it.
 *
 * The composite primary key is the rule that a tag cannot be applied twice.
 */

const VendorStyleTag = sequelize.define('VendorStyleTag', {
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
    primaryKey: true,
  },
  tag: {
    type: DataTypes.STRING(60),
    allowNull: false,
    primaryKey: true,
  },
}, {
  tableName: 'vendor_style_tags',
  timestamps: false,
  // "Every vendor tagged Bohemian" — the lookup the JSON column could not do.
  indexes: [{ fields: ['tag'], name: 'vendor_style_tags_tag_idx' }],
});

const CoupleStyleTag = sequelize.define('CoupleStyleTag', {
  couple_user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    primaryKey: true,
  },
  tag: {
    type: DataTypes.STRING(60),
    allowNull: false,
    primaryKey: true,
  },
}, {
  tableName: 'couple_style_tags',
  timestamps: false,
  indexes: [{ fields: ['tag'], name: 'couple_style_tags_tag_idx' }],
});

module.exports = { VendorStyleTag, CoupleStyleTag };

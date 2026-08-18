const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

/**
 * Wedding-class packages a vendor registers, replacing the `vendors.packages`
 * JSON array.
 *
 * This was the worst of the schema's 1NF violations: an array of objects, each
 * of which held a nested `inclusions` array — a repeating group inside a
 * repeating group. It needs two tables, not one.
 */
const VendorPackage = sequelize.define('VendorPackage', {
  package_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  tier: {
    // The wedding-class criteria the Flutter VendorClassService reads.
    type: DataTypes.ENUM('luxury', 'starter'),
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING(200),
    allowNull: false,
  },
  price: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: true,
  },
  /// Preserves the order the vendor authored them in — a JSON array carried
  /// that implicitly, rows do not.
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'vendor_packages',
  timestamps: false,
  indexes: [
    { fields: ['vendor_id'], name: 'vendor_packages_vendor_id_idx' },
    { fields: ['tier'], name: 'vendor_packages_tier_idx' },
  ],
});

/// One line item inside a package. Ordered, because "what you get" reads as a
/// list the vendor wrote deliberately.
const VendorPackageInclusion = sequelize.define('VendorPackageInclusion', {
  package_id: {
    type: DataTypes.UUID,
    allowNull: false,
    primaryKey: true,
  },
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    primaryKey: true,
  },
  description: {
    type: DataTypes.STRING(300),
    allowNull: false,
  },
}, {
  tableName: 'vendor_package_inclusions',
  timestamps: false,
});

module.exports = { VendorPackage, VendorPackageInclusion };

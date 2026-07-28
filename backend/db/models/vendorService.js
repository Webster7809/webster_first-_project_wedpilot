const { DataTypes } = require('sequelize');
const sequelize = require('../sequelize');

const VendorService = sequelize.define('VendorService', {
  service_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  vendor_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  price_min: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  price_max: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  unit: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'package',
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  // Maximum guests this package can serve — mandatory for every new/edited
  // listing (see POST/PUT /me/services validation in routes/vendors.js) and
  // used by the vendor-matching pipeline to reject packages too small for
  // the couple's guest count. Stays allowNull here (rather than a hard
  // NOT NULL column) purely so pre-existing rows from before this field was
  // required don't break `sequelize.sync({ alter: true })` on deploy — see
  // backend/scripts/backfillGuestCapacity.js, which assigns every such row a
  // category-appropriate default. Null should not occur on any row created
  // or edited after that backfill runs.
  max_guests: {
    type: DataTypes.INTEGER,
    allowNull: true,
    // Upper bound mirrors MAX_REALISTIC_GUEST_COUNT in routes/vendors.js —
    // kept here too as a last line of defense against any write path that
    // bypasses the route handler's own check.
    validate: { min: 1, max: 20000 },
  },
}, {
  tableName: 'vendor_services',
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  // Named explicitly to avoid Sequelize piling up duplicate indexes on every
  // alter-sync (see vendor.js for the same pattern). vendor_id backs every
  // per-vendor services lookup (serializeVendor); max_guests backs the
  // min_guests directory/matching filter (GET /api/vendors) — both sit on
  // the hot path for every vendor-match run, not just occasional queries.
  indexes: [
    { fields: ['vendor_id'], name: 'vendor_services_vendor_id_idx' },
    { fields: ['max_guests'], name: 'vendor_services_max_guests_idx' },
  ],
});

module.exports = VendorService;

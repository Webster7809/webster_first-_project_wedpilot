// Test database bootstrap.
//
// Points the app's Sequelize instance at a throwaway schema BEFORE any model
// is required, so tests never touch the development database. Runs against the
// same MySQL the app uses in production rather than an in-memory substitute —
// the behaviour under test (JSON column writes, unique indexes, date columns)
// is dialect-specific, and a sqlite stand-in would prove nothing about it.
require('dotenv').config();

const TEST_DB = process.env.TEST_DB_NAME || `${process.env.DB_NAME}_test`;
process.env.DB_NAME = TEST_DB;

const mysql = require('mysql2/promise');

/// Dropped and recreated rather than reused: migration 004 adds foreign keys,
/// and `sync({ force: true })` cannot drop a table another table references.
/// A fresh schema also means a test run can never inherit state from the last.
async function createTestSchema() {
  const admin = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });
  await admin.query(`DROP DATABASE IF EXISTS \`${TEST_DB}\``);
  await admin.query(`CREATE DATABASE \`${TEST_DB}\``);
  await admin.end();
}

/// Builds the schema the way production does — by running the migrations —
/// rather than from sync(). Tests then run against the real thing, foreign
/// keys included, instead of an approximation that would hide constraint
/// violations until deploy.
function runMigrations() {
  const { execFileSync } = require('node:child_process');
  const path = require('path');
  execFileSync(process.execPath, [path.join(__dirname, '..', '..', 'db', 'migrate.js')], {
    stdio: 'pipe',
    env: { ...process.env, DB_NAME: TEST_DB },
  });
}

/// Loads every model so sync() creates the whole schema, not just the tables a
/// given test file happens to require.
function loadAllModels() {
  const fs = require('fs');
  const path = require('path');
  const dir = path.join(__dirname, '..', '..', 'db', 'models');
  for (const file of fs.readdirSync(dir)) {
    if (file.endsWith('.js')) require(path.join(dir, file));
  }
}

async function setupDatabase() {
  await createTestSchema();
  runMigrations();
  loadAllModels();
  const sequelize = require('../../db/sequelize');
  await sequelize.authenticate();
  return sequelize;
}

/// Empties every table between tests. FK checks are toggled off because the
/// schema has no declared foreign keys today but may gain them — truncating in
/// dependency order would then start failing for reasons unrelated to a test.
async function truncateAll() {
  const sequelize = require('../../db/sequelize');
  await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const model of Object.values(sequelize.models)) {
    await sequelize.query(`TRUNCATE TABLE \`${model.getTableName()}\``);
  }
  await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
}

async function closeDatabase() {
  const sequelize = require('../../db/sequelize');
  await sequelize.close();
}

module.exports = { setupDatabase, truncateAll, closeDatabase, TEST_DB };

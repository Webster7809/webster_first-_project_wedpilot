#!/usr/bin/env node
/**
 * Applies pending migrations from backend/migrations, in filename order.
 *
 * Replaces `sequelize.sync({ alter: true })` as the way production gets its
 * schema. `alter` rewrites live tables to match the models on every boot, and
 * on MySQL changing a column type means dropping and recreating it — losing
 * the data in it. That is fine against a scratch dev database and completely
 * unacceptable against a hosted one.
 *
 * Deliberately hand-rolled rather than sequelize-cli/umzug: it is ~70 lines,
 * needs no new dependency in a deploy image, and reuses the Sequelize
 * instance the app already configures.
 *
 * Run it as a release/pre-deploy step:  npm run migrate && npm start
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Sequelize } = require('sequelize');
const sequelize = require('./sequelize');

const MIGRATIONS_DIR = path.join(__dirname, '..', 'migrations');

async function ensureMetaTable() {
  await sequelize.query(
    `CREATE TABLE IF NOT EXISTS schema_migrations (
       name VARCHAR(255) NOT NULL PRIMARY KEY,
       applied_at DATETIME NOT NULL
     )`,
  );
}

async function appliedMigrations() {
  const [rows] = await sequelize.query('SELECT name FROM schema_migrations');
  return new Set(rows.map((r) => r.name));
}

async function run() {
  await sequelize.authenticate();
  await ensureMetaTable();

  const applied = await appliedMigrations();
  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.js'))
    .sort();

  const pending = files.filter((f) => !applied.has(f));
  if (pending.length === 0) {
    console.log('No pending migrations.');
    return;
  }

  const queryInterface = sequelize.getQueryInterface();
  for (const file of pending) {
    process.stdout.write(`Applying ${file} ... `);
    // No transaction wrapper: MySQL commits DDL implicitly, so a rollback
    // here would be a false promise. Each migration is written to be
    // idempotent instead, so a failed run can simply be re-run.
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const migration = require(path.join(MIGRATIONS_DIR, file));
    await migration.up(queryInterface, Sequelize, sequelize);
    await sequelize.query(
      'INSERT INTO schema_migrations (name, applied_at) VALUES (?, NOW())',
      { replacements: [file] },
    );
    console.log('done');
  }

  console.log(`Applied ${pending.length} migration(s).`);
}

run()
  .then(() => sequelize.close())
  .then(() => process.exit(0))
  .catch(async (err) => {
    console.error('Migration failed:', err.message);
    await sequelize.close().catch(() => {});
    process.exit(1);
  });

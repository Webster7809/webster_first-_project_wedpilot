# Wedpilot backend

Express + Sequelize + MySQL REST API for the Wedpilot Flutter app.

## Setup

```bash
npm install
cp .env.example .env   # fill in DB_*, JWT_SECRET, OPENROUTER_API_KEY, etc.
npm run dev             # nodemon, restarts on change — or `npm start` for a plain run
```

Requires a running MySQL instance matching `DB_HOST`/`DB_PORT`/`DB_USER`/`DB_PASSWORD`/`DB_NAME` in `.env`. The server creates/updates tables itself on boot via `sequelize.sync({ alter: true })` — no separate migration step.

## Seed scripts — real data vs. dev-only fictional data

`scripts/` contains one-off Node scripts, run manually (`node scripts/<name>.js`) — none of them run automatically on `npm start`/`npm run dev`.

**Safe to run against any environment, including production:**
- `seedCuratedVendors.js` / `removeCuratedVendors.js` — Wedpilot's real curated vendor catalog (sourced from `curated_vendors_export.json`), added as real database rows.

**DEV-ONLY — never run against a production `DB_NAME`:**
- `seedTestVendors.js` / `removeTestVendors.js` — creates/removes ~40 **fictional** vendors (`.test` email domains) with fabricated reviews and ratings, purely so budget-based AI vendor matching can be exercised manually during development. Both scripts now carry a warning comment at the top as well.

Before running any seed script, double-check `DB_NAME` in your active `.env` is pointing at a local/dev database, not production.

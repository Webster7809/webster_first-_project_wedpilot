# Wedpilot

An AI-assisted wedding budget planning and vendor-matching app for couples, vendors, and admins. Flutter (Android + Web) frontend, Express/Sequelize/MySQL backend (`backend/`).

## Prerequisites

- Flutter SDK (Dart `^3.12.0`), `flutter doctor` reporting no blocking issues
- Android Studio (for the Android SDK/platform tools) or standalone `adb`
- Node.js + a running MySQL instance for the backend (`backend/.env.example` documents required variables)

## Running the backend

```bash
cd backend
npm install
npm run dev        # nodemon, restarts on change
```

The server listens on the port from `backend/.env` (default `3000`) on all network interfaces.

## Running the app

### On an emulator or web

```bash
flutter pub get
flutter run             # Android emulator or connected device
flutter run -d chrome   # Web
```

No extra config needed — the app defaults to `10.0.2.2` (Android emulator's alias for host `localhost`) or `localhost` (web/desktop).

### On a physical Android phone (USB debugging + Hot Reload)

A physical phone can't reach your PC via `localhost` or `10.0.2.2` — it needs your PC's actual LAN IP address, and both devices need to be on the same Wi-Fi/network.

1. **Enable Developer Options + USB debugging on the phone**: Settings → About phone → tap "Build number" 7 times → Developer Options appears in Settings → enable "USB debugging".
2. **Connect the phone via USB** and accept the "Allow USB debugging?" prompt on the phone when it appears.
3. **Verify the device is detected**:
   ```bash
   flutter devices
   ```
   Your phone should be listed. If not, check the USB cable (must support data, not charge-only) and that you accepted the debugging prompt.
4. **Find your PC's LAN IPv4 address**:
   ```bash
   ipconfig
   ```
   Look for the "IPv4 Address" under your active Wi-Fi adapter (e.g. `192.168.1.20`).
5. **Allow inbound connections to the backend port through Windows Firewall** (one-time, run as Administrator):
   ```powershell
   New-NetFirewallRule -DisplayName "Wedpilot backend dev" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
   ```
6. **Run the app pointed at your PC's IP**:
   ```bash
   flutter run --dart-define=API_HOST=192.168.1.20
   ```
   Replace `192.168.1.20` with the IP from step 4. This flag is read by `lib/core/config/api_config.dart`, which every API service shares.

Once running, **Hot Reload** applies on save automatically in most editors/IDEs (VS Code: `Ctrl+S` triggers it if the Flutter extension's "Hot Reload on Save" is on; otherwise press `r` in the terminal running `flutter run`, or hit the Hot Reload button in the IDE). Use Hot Restart (`R` in the terminal, or the IDE's restart button) when you change things Hot Reload can't handle — `main()`, global/static state, enum shapes, native/plugin code.

**Tip**: if you frequently switch between emulator and physical-device testing, save the `--dart-define=API_HOST=...` flag as a VS Code launch configuration (`.vscode/launch.json`) argument so you don't have to retype it.

## Building a release APK

See `android/app/build.gradle.kts` for the release signing setup. Summary:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-host
```

`API_BASE_URL` is **required** for any release artifact and must be `https`. A release build without it throws at the first API call rather than silently trying to reach `localhost` — which on a user's handset is the handset itself (see `lib/core/config/api_config.dart`).

Requires a local `android/key.properties` (gitignored) pointing at an upload keystore — see comments in `build.gradle.kts` for the one-time `keytool` command. Without `key.properties` present, release builds fall back to debug signing so `flutter run --release` still works during development. **A Play Store upload needs the real keystore** — an APK signed with the debug key is rejected.

## Deploying the backend

Set `NODE_ENV=production` on the deployed instance. That switches on the startup config gate (`backend/config/requireEnv.js`), HSTS, `trust proxy`, generic error responses, and migration-managed schema.

The gate refuses to start unless the following are set to real values — each one otherwise fails as a working server with a quietly broken feature rather than a failed deploy:

| Variable | Why it is mandatory |
| --- | --- |
| `JWT_SECRET` | Min 32 chars (`openssl rand -base64 32`). Unset, every login and authenticated request fails. |
| `CORS_ORIGINS` | Comma-separated web origins. Absent, the alternative is an open CORS policy. |
| `PUBLIC_WEB_BASE_URL` | Public `https` origin baked into verification and reset emails. A localhost value sends every recipient to their own machine. |
| `SMTP_HOST` / `SMTP_USER` / `SMTP_PASS` | Unconfigured, the mailer logs links to the console instead of sending — a silent account-recovery outage, since the API still answers "a reset link has been sent". |
| `DB_HOST` / `DB_USER` / `DB_NAME` | Database connection. |

Placeholder values copied from `.env.example` count as unset.

Schema is applied as an explicit release step, never on boot — `sequelize.sync({ alter: true })` is development-only because a MySQL column type change is a drop-and-recreate:

```bash
cd backend
npm ci
npm run migrate
npm start
```

## Running with Docker

Brings up MySQL, the schema migration, the API, and the Flutter web build together.

```bash
cp .env.docker.example .env    # then fill it in — see the comments in that file
docker compose up --build
```

Web app on `http://localhost:8080`, API on `http://localhost:3000`.

| File | Role |
| --- | --- |
| `backend/Dockerfile` | API image — multi-stage, runs as non-root `node`, `/health` healthcheck |
| `Dockerfile.web` | Flutter web build → nginx (build context is the repo root) |
| `docker/nginx.conf` | Static serving: gzip, SPA fallback, long-lived asset caching |
| `docker-compose.yml` | Wires the four services together |
| `.env.docker.example` | Template for the compose `.env` (gitignored) |

Startup order is enforced, not guessed: `db` must pass its healthcheck before `migrate` runs, and `migrate` must **exit successfully** before `api` starts. Migrations are idempotent, so re-running on every `up` is a no-op once the schema is current.

Two things are compile-time rather than runtime, because `ApiConfig` reads them via `String.fromEnvironment`:

- `API_BASE_URL` and `GOOGLE_SERVER_CLIENT_ID` are baked into the web bundle. Changing either needs `docker compose build web` — a restart alone will not pick them up.

State lives in two named volumes: `db_data` (MySQL) and `uploads` (user-uploaded media, the only application state outside the database). `docker compose down` preserves both; `docker compose down -v` **deletes them**.

Create the first admin account once the stack is up:

```bash
docker compose exec api node scripts/createAdmin.js
```

The compose file sets `NODE_ENV=production`, so the startup config gate described above applies — the API will refuse to start on a missing or placeholder value and name it.

## Analyze & test

```bash
flutter analyze
flutter test

cd backend && npm test
```

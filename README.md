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
flutter build apk --release
```

Requires a local `android/key.properties` (gitignored) pointing at an upload keystore — see comments in `build.gradle.kts` for the one-time `keytool` command. Without `key.properties` present, release builds fall back to debug signing so `flutter run --release` still works during development.

## Analyze & test

```bash
flutter analyze
flutter test
```

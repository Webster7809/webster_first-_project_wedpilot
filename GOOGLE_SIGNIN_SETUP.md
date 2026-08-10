# Google Sign-In setup

The code is already wired up. What's missing is the OAuth credentials —
without them the button shows "Google sign-in isn't set up yet on this build"
and the backend's `POST /api/auth/google` responds `501`. This is the
checklist to fill that gap.

## Values you'll need

| What | Value |
| --- | --- |
| Android package name | `com.wedpilot.app` |
| Debug keystore SHA-1 | `10:67:3E:ED:14:76:36:47:10:BC:5F:60:0D:2C:23:11:FF:87:FE:CF` |

The SHA-1 above is the **debug** key, which is what release builds also use
right now (`android/app/build.gradle.kts` falls back to it when
`android/key.properties` is absent). If you later create a real release
keystore for the Play Store, register that keystore's SHA-1 as a second
Android client in the same project.

## Steps

1. **Create a Google Cloud project** at https://console.cloud.google.com
   (or reuse an existing one).

2. **Configure the OAuth consent screen** — APIs & Services → OAuth consent
   screen. External user type, fill in app name/support email, and add your
   own Google account under "Test users" so you can sign in before the app
   is verified.

3. **Create an Android OAuth client** — APIs & Services → Credentials →
   Create Credentials → OAuth client ID → Android.
   - Package name: `com.wedpilot.app`
   - SHA-1: the fingerprint from the table above

   This client authorizes the app itself. You don't paste its ID anywhere —
   Google matches the app by package name + signature.

4. **Create a Web OAuth client** — same menu, type **Web application**. This
   one is the *audience* of the ID token, and its client ID is what both the
   app and the backend need. Copy it; it looks like
   `123456789-abcdef.apps.googleusercontent.com`.

5. **Give the backend the Web client ID** — in `backend/.env`:
   ```
   GOOGLE_CLIENT_ID=123456789-abcdef.apps.googleusercontent.com
   ```
   Restart the backend afterward.

6. **Give the app the same Web client ID** at build time:
   ```
   flutter build apk --release \
     --dart-define=API_HOST=localhost \
     --dart-define=GOOGLE_SERVER_CLIENT_ID=123456789-abcdef.apps.googleusercontent.com
   ```
   The same `--dart-define` works with `flutter run`.

   Both sides must use the **Web** client ID — not the Android one. That's
   the usual reason a first attempt fails with "Invalid Google sign-in
   token": the token's audience doesn't match what the server verifies.

## Verifying it works

- Tapping "Continue with Google" opens the native account picker.
- Picking an account lands you in the app, signed in.
- A brand-new Google account goes through onboarding; an account whose email
  already exists signs straight into that existing account, keeping its role.

## Notes

- Accounts created via Google get a random unusable password hash — password
  login for that email will never succeed, which is intended.
- The `role` sent alongside the token only applies the first time an email is
  seen. On the register screen it follows the Couple/Vendor tab; on the login
  screen it's `couple`, which is irrelevant for anyone who already has an
  account.
- The button currently renders a plain "G" circle rather than Google's
  official multi-color logo. Before shipping publicly, swap in the real asset
  to satisfy Google's branding guidelines (see `lib/widgets/google_signin_button.dart`).

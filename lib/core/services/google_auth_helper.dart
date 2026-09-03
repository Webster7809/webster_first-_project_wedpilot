import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';

/// Thrown when the user backs out of the native account picker — callers
/// should treat this as a silent no-op, not an error to surface.
class GoogleAuthCancelledException implements Exception {}

/// Thrown when GOOGLE_SERVER_CLIENT_ID hasn't been supplied at build time —
/// the OAuth client hasn't been created yet, so there's nothing to sign in
/// against. See GOOGLE_SIGNIN_SETUP.md.
class GoogleAuthNotConfiguredException implements Exception {}

class GoogleAuthHelper {
  GoogleAuthHelper._();
  static final GoogleAuthHelper instance = GoogleAuthHelper._();

  // GoogleSignIn.instance.initialize() must run exactly once, before any
  // other call — this Future is that guard, shared across every signIn().
  Future<void>? _initFuture;

  /// Starts (or awaits an already-started) GoogleSignIn.initialize(). Public
  /// because the web path has to call this itself before rendering Google's
  /// own sign-in button (see GoogleSignInButton) — unlike [signIn]'s native
  /// path, there's no tap on our side to lazily trigger it from first.
  Future<void> ensureInitialized() {
    final clientId = ApiConfig.googleServerClientId.isNotEmpty
        ? ApiConfig.googleServerClientId
        : null;
    // google_sign_in_web's plugin asserts `serverClientId == null` and
    // requires the Web client ID via `clientId` instead (its own JS SDK,
    // not a server-verified handoff) — passing serverClientId there leaves
    // its client ID unset and the plugin throws on first use. Native
    // platforms want the opposite: `serverClientId` is what makes the
    // returned ID token audienced to this (Web) client so the backend can
    // verify it; passing it as `clientId` there would instead try to
    // override the app's own native client. Same value, different slot per
    // platform — see GOOGLE_SIGNIN_SETUP.md.
    return _initFuture ??= GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? clientId : null,
      serverClientId: kIsWeb ? null : clientId,
    );
  }

  /// Runs the native Google account picker and returns the ID token that
  /// POST /api/auth/google verifies server-side. Android/iOS only —
  /// google_sign_in_web's authenticate() always throws UnimplementedError;
  /// web signs in through [signInEvents] instead, driven by the SDK's own
  /// rendered button (see google_web_button_web.dart).
  Future<String> signIn() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      throw GoogleAuthNotConfiguredException();
    }
    await ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an identity token.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleAuthCancelledException();
      }
      rethrow;
    }
  }

  /// Accounts reported by the SDK once a sign-in completes — the only way
  /// web learns of one, since its rendered button (not app code) drives the
  /// GIS/FedCM flow rather than returning from an awaited call.
  Stream<GoogleSignInAccount> get signInEvents {
    return GoogleSignIn.instance.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .map(
          (event) =>
              (event as GoogleSignInAuthenticationEventSignIn).user,
        );
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();
}

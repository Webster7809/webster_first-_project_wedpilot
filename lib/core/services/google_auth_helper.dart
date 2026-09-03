import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';

/// Thrown when the user backs out of the native account picker — callers
/// should treat this as a silent no-op, not an error to surface.
class GoogleAuthCancelledException implements Exception {}

/// Thrown when GOOGLE_SERVER_CLIENT_ID hasn't been supplied at build time —
/// the OAuth client hasn't been created yet, so there's nothing to sign in
/// against. See GOOGLE_SIGNIN_SETUP.md.
class GoogleAuthNotConfiguredException implements Exception {}

/// Android/iOS sign-in only. Web talks to Google's Identity Services SDK
/// directly instead (see google_web_button_web.dart) — google_sign_in_web's
/// authenticate() always throws UnimplementedError there, and its
/// renderButton() hardcodes auto_select in a way this app doesn't want. See
/// GOOGLE_SIGNIN_SETUP.md.
class GoogleAuthHelper {
  GoogleAuthHelper._();
  static final GoogleAuthHelper instance = GoogleAuthHelper._();

  // GoogleSignIn.instance.initialize() must run exactly once, before any
  // other call — this Future is that guard, shared across every signIn().
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    final clientId = ApiConfig.googleServerClientId.isNotEmpty
        ? ApiConfig.googleServerClientId
        : null;
    return _initFuture ??= GoogleSignIn.instance.initialize(
      serverClientId: clientId,
    );
  }

  /// Runs the native Google account picker and returns the ID token that
  /// POST /api/auth/google verifies server-side.
  Future<String> signIn() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      throw GoogleAuthNotConfiguredException();
    }
    await _ensureInitialized();
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

  Future<void> signOut() => GoogleSignIn.instance.signOut();
}

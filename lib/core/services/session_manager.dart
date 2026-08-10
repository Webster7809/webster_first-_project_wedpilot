import 'auth_service.dart';
import 'token_service.dart';

/// Coordinates refreshing the short-lived access token when it expires
/// mid-session, so a couple filling out a long form doesn't get silently
/// broken an hour after login.
///
/// This sits below Riverpod (every `*ApiService` is a plain singleton, not
/// provider-constructed), so [AuthNotifier] wires itself in via the two
/// callbacks below rather than this class reaching up into app state
/// directly. See `authProvider`'s constructor for the wiring.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  /// Called with the new access token the moment a refresh succeeds, so
  /// [AuthNotifier]'s in-memory copy (which every provider reads per-call)
  /// stays in sync without waiting for the next full session restore.
  void Function(String accessToken)? onTokenRefreshed;

  /// Called when the refresh token itself is invalid, expired, or the
  /// account was suspended — there's no way back into this session short of
  /// a real login, so the app should drop back to the login screen rather
  /// than keep silently failing every request.
  void Function()? onSessionExpired;

  Future<String?>? _inFlight;

  /// Exchanges the stored refresh token for a fresh pair. Concurrent callers
  /// (several requests 401 around the same moment) share one in-flight
  /// refresh rather than each spending the couple's session on a separate
  /// round trip — Dio's own interceptor is what actually calls this per
  /// failed request; see `authenticated_dio.dart`.
  Future<String?> refreshAccessToken() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await tokenService.getRefreshToken();
    if (refreshToken == null) {
      onSessionExpired?.call();
      return null;
    }

    try {
      final result = await AuthService.instance.refresh(refreshToken);
      await tokenService.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        accessExpiry: result.accessExpiry,
        refreshExpiry: result.refreshExpiry,
      );
      onTokenRefreshed?.call(result.accessToken);
      return result.accessToken;
    } on AuthApiException {
      // The refresh token itself was rejected (expired/invalid/revoked via
      // suspension) — no retry can fix this, only a real login can.
      await tokenService.clearTokens();
      onSessionExpired?.call();
      return null;
    } catch (_) {
      // A network-level failure reaching the refresh endpoint is transient,
      // not a dead session — leave the stored tokens alone so the next
      // 401 gets another chance once connectivity is back.
      return null;
    }
  }
}

final sessionManager = SessionManager.instance;

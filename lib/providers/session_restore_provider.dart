import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../core/utils/app_logger.dart';
import '../core/services/session_manager.dart';
import '../core/services/token_service.dart';
import 'auth_provider.dart';

/// Runs once at app boot: if a valid stored session exists, re-validates it
/// against the backend and restores it into [authProvider] before the router
/// evaluates any redirects.
final sessionRestoreProvider = FutureProvider<void>((ref) async {
  try {
    if (!await tokenService.hasStoredSession()) return;

    final refreshValid = await tokenService.isRefreshTokenValid();
    if (!refreshValid) {
      await tokenService.clearTokens();
      return;
    }

    // A closed-then-reopened app very commonly outlives the 1h access token
    // while the 7-day refresh token is still good — refresh it here instead
    // of forcing a fresh login every single cold start past an hour.
    final accessValid = await tokenService.isAccessTokenValid();
    var token = accessValid ? await tokenService.getAccessToken() : null;
    if (token == null) {
      token = await sessionManager.refreshAccessToken();
      if (token == null) return; // refresh itself already cleared tokens
    }

    final user = await AuthService.instance.fetchCurrentUser(token);
    await ref.read(authProvider.notifier).restoreSession(user, accessToken: token);
  } catch (e, stackTrace) {
    // The caught object here is very often a DioException, whose toString
    // includes the full request — Authorization header included. It must not
    // reach logcat in a release build; AppLogger keeps it to debug consoles
    // and crash reporting.
    AppLogger.error('Session restore failed, treating as logged out', e, stackTrace);
    await tokenService.clearTokens();
  }
});

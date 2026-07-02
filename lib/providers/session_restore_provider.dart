import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
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

    // No refresh-token endpoint exists yet, so an expired access token forces
    // a fresh login even if the refresh token is still valid.
    final accessValid = await tokenService.isAccessTokenValid();
    if (!accessValid) {
      await tokenService.clearTokens();
      return;
    }

    final token = await tokenService.getAccessToken();
    final user = await AuthService.instance.fetchCurrentUser(token!);
    await ref.read(authProvider.notifier).restoreSession(user, accessToken: token);
  } catch (e) {
    // ignore: avoid_print
    print('[sessionRestore] failed, treating as logged out: $e');
    await tokenService.clearTokens();
  }
});

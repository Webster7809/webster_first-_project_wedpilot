import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInAccount;
import '../core/services/auth_service.dart';
import '../core/services/couple_profile_service.dart';
import '../core/services/google_auth_helper.dart';
import '../core/services/session_manager.dart';
import '../core/services/token_service.dart';
import '../core/services/vendor_api_service.dart';
import '../core/utils/app_logger.dart';
import '../models/user.dart';
import '../models/couple_profile.dart';
import '../models/vendor_profile.dart';
import 'session_scoped_providers.dart';
import '../core/services/api_error.dart';

class AuthState {
  final User? user;
  final CoupleProfile? coupleProfile;
  final VendorProfile? vendorProfile;
  final bool isLoading;
  final String? error;
  final bool needsOnboarding;

  const AuthState({
    this.user,
    this.coupleProfile,
    this.vendorProfile,
    this.isLoading = false,
    this.error,
    this.needsOnboarding = false,
  });

  bool get isAuthenticated => user != null;
  bool get isCouple => user?.role == UserRole.couple;
  bool get isVendor => user?.role == UserRole.vendor;
  bool get isAdmin => user?.role == UserRole.admin;

  AuthState copyWith({
    User? user,
    CoupleProfile? coupleProfile,
    VendorProfile? vendorProfile,
    bool? isLoading,
    String? error,
    bool? needsOnboarding,
  }) =>
      AuthState(
        user: user ?? this.user,
        coupleProfile: coupleProfile ?? this.coupleProfile,
        vendorProfile: vendorProfile ?? this.vendorProfile,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService, this._ref) : super(const AuthState()) {
    // SessionManager sits below Riverpod (every *ApiService is a plain
    // singleton, refreshed transparently by authenticated_dio.dart's 401
    // interceptor), so it reaches back into app state through these two
    // callbacks rather than AuthNotifier polling it.
    sessionManager.onTokenRefreshed = (token) => _accessToken = token;
    sessionManager.onSessionExpired = () {
      // The refresh token itself was rejected — e.g. its 7-day life ran out,
      // or an admin suspended the account mid-session. There's no session
      // left to preserve, so this drops straight to a logged-out state;
      // logout() ends up re-clearing tokens SessionManager already cleared,
      // which is harmless.
      unawaited(logout());
    };
  }

  final AuthService _authService;

  /// Used only to drop per-account provider caches when the signed-in
  /// identity changes — see [invalidateSessionScopedProviders].
  final Ref _ref;

  // Couple profiles are persisted server-side (see couple_profile_service.dart);
  // this map is just a same-session cache to avoid redundant refetches, not the
  // source of truth. Vendor profiles remain in-memory only — persisting them is
  // a separate future phase.
  final _coupleProfiles = <String, CoupleProfile>{};
  final _vendorProfiles = <String, VendorProfile>{};

  // Captured at register() time so a couple's partner name survives through to
  // the onboarding wizard's first save, since no profile row exists yet to hold it.
  String? _pendingPartnerName;

  // In-memory copy of the current session's access token. flutter_secure_storage's
  // web backend can throw OperationError when decrypting a previously-written
  // value back (a browser WebCrypto interop issue, not specific to reloads), so
  // authenticated calls made later in the same session use this instead of
  // re-reading from secure storage — only cold-start restore needs that read.
  String? _accessToken;

  /// The current session's bearer token, for any provider/service that needs
  /// to authenticate a backend call. Null means "not signed in."
  String? get accessToken => _accessToken;

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(email: email, password: password);
      await _applyAuthResult(result);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e, stackTrace) {
      // Anything reaching here is NOT an AuthApiException (a clean backend
      // rejection) — it's something describeError can't name specifically
      // (falls back to "Something went wrong"), so the real cause would
      // otherwise vanish silently. Logged so it's visible in `adb logcat`
      // even on a build with no attached debug session.
      AppLogger.error('Login failed', e, stackTrace);
      state = state.copyWith(isLoading: false, error: describeError(e));
    }
  }

  /// Signs in (or, for a brand-new email, registers) via Google. [role] only
  /// decides the account's role the first time this email is seen — an
  /// existing account keeps whatever role it already has server-side.
  /// A cancelled account picker is treated as a silent no-op, not an error.
  Future<void> loginWithGoogle(UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await GoogleAuthHelper.instance.signIn();
      await _finishGoogleAuth(idToken, role);
    } on GoogleAuthCancelledException {
      state = state.copyWith(isLoading: false);
    } on GoogleAuthNotConfiguredException {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in isn’t set up yet on this build.',
      );
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e, stackTrace) {
      AppLogger.error('Google sign-in failed', e, stackTrace);
      state = state.copyWith(isLoading: false, error: describeError(e));
    }
  }

  /// Completes a Google sign-in on web, where GoogleSignInButton renders
  /// Google's own SDK button instead of calling [loginWithGoogle] directly
  /// (google_sign_in_web has no imperative authenticate() call) — the
  /// account arrives here via GoogleAuthHelper.signInEvents once the user
  /// finishes Google's own flow.
  Future<void> completeGoogleSignIn(GoogleSignInAccount account, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an identity token.');
      }
      await _finishGoogleAuth(idToken, role);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e, stackTrace) {
      AppLogger.error('Google sign-in failed', e, stackTrace);
      state = state.copyWith(isLoading: false, error: describeError(e));
    }
  }

  Future<void> _finishGoogleAuth(String idToken, UserRole role) async {
    final result = await _authService.googleAuth(idToken: idToken, role: role);
    // No forceOnboarding: a brand-new account already resolves
    // needsOnboarding=true on its own (no profile row exists yet), while a
    // returning account correctly skips back onboarding it already did.
    await _applyAuthResult(result);
  }

  Future<void> register(
    String partner1Name,
    String email,
    String password,
    UserRole role, {
    String? partner2Name,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    _pendingPartnerName = partner2Name;
    try {
      final result = await _authService.register(
        name: partner1Name,
        email: email,
        password: password,
        role: role,
        // Was accepted here and never forwarded — every phone number typed
        // at signup was silently discarded, which is exactly why the vendor
        // onboarding wizard's contact step had nothing to prefill from and
        // made vendors retype a number they'd just given.
        phone: phone,
      );
      await _applyAuthResult(result, forceOnboarding: true);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e, stackTrace) {
      AppLogger.error('Registration failed', e, stackTrace);
      state = state.copyWith(isLoading: false, error: describeError(e));
    }
  }

  Future<void> _applyAuthResult(AuthResult result, {bool forceOnboarding = false}) async {
    await tokenService.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      accessExpiry: result.accessExpiry,
      refreshExpiry: result.refreshExpiry,
    );
    _accessToken = result.accessToken;
    // A session can be replaced without an explicit logout — an expired
    // refresh token bounces straight to the login screen — so the reset has to
    // happen on the way in as well as on the way out.
    invalidateSessionScopedProviders(_ref);

    final user = result.user;
    CoupleProfile? coupleProfile;
    VendorProfile? vendorProfile;
    bool needsOnboarding;

    if (user.role == UserRole.couple) {
      try {
        coupleProfile = await CoupleProfileService.instance.fetchProfile(result.accessToken);
        if (coupleProfile != null) _coupleProfiles[user.id] = coupleProfile;
        needsOnboarding = coupleProfile == null;
      } catch (_) {
        // Couldn't confirm profile status (network/server hiccup) — do NOT
        // treat this the same as "definitely no profile", or a returning
        // couple would incorrectly get bounced into onboarding.
        needsOnboarding = false;
      }
    } else if (user.role == UserRole.vendor) {
      try {
        vendorProfile = await VendorApiService.instance.fetchMyProfile(result.accessToken);
        if (vendorProfile != null) _vendorProfiles[user.id] = vendorProfile;
        needsOnboarding = forceOnboarding || vendorProfile == null;
      } catch (_) {
        needsOnboarding = forceOnboarding;
      }
    } else {
      needsOnboarding = false;
    }

    state = state.copyWith(
      user: user,
      coupleProfile: coupleProfile,
      vendorProfile: vendorProfile,
      isLoading: false,
      needsOnboarding: needsOnboarding,
    );
  }

  /// Restores a session on app cold-start after the stored access token was
  /// validated against the backend (see sessionRestoreProvider).
  Future<void> restoreSession(User user, {required String accessToken}) async {
    _accessToken = accessToken;
    CoupleProfile? coupleProfile;
    VendorProfile? vendorProfile;
    bool needsOnboarding;

    if (user.role == UserRole.couple) {
      try {
        coupleProfile = await CoupleProfileService.instance.fetchProfile(accessToken);
        if (coupleProfile != null) _coupleProfiles[user.id] = coupleProfile;
        needsOnboarding = coupleProfile == null;
      } catch (_) {
        // Couldn't confirm profile status (network/server hiccup) — do NOT
        // treat this the same as "definitely no profile", or a returning
        // couple would incorrectly get bounced into onboarding on every
        // cold app start until the request happens to succeed.
        needsOnboarding = false;
      }
    } else if (user.role == UserRole.vendor) {
      try {
        vendorProfile = await VendorApiService.instance.fetchMyProfile(accessToken);
        if (vendorProfile != null) _vendorProfiles[user.id] = vendorProfile;
        needsOnboarding = vendorProfile == null;
      } catch (_) {
        needsOnboarding = false;
      }
    } else {
      needsOnboarding = false;
    }

    state = state.copyWith(
      user: user,
      coupleProfile: coupleProfile,
      vendorProfile: vendorProfile,
      needsOnboarding: needsOnboarding,
    );
  }

  Future<void> updateCoupleProfile({
    required List<String> selectedItems,
    required double budget,
    required String weddingStyle,
    required String weddingClass,
    required int guestCount,
    required String location,
    DateTime? weddingDate,
  }) async {
    final profile = CoupleProfile(
      id: state.coupleProfile?.id ?? '',
      userId: state.user?.id ?? '',
      partnerName: state.coupleProfile?.partnerName ?? _pendingPartnerName,
      weddingDate: weddingDate ?? state.coupleProfile?.weddingDate,
      location: location.isNotEmpty ? location : null,
      guestCount: guestCount > 0 ? guestCount : null,
      styleTags: [weddingStyle, weddingClass, ...selectedItems],
      totalBudget: budget > 0 ? budget : null,
      currency: 'ZMW',
    );

    final userId = state.user?.id;
    if (userId == null || _accessToken == null) {
      state = state.copyWith(coupleProfile: profile, needsOnboarding: false);
      return;
    }

    try {
      final saved = await CoupleProfileService.instance.saveProfile(_accessToken!, profile);
      _coupleProfiles[userId] = saved;
      state = state.copyWith(coupleProfile: saved, needsOnboarding: false);
    } on CoupleProfileApiException catch (e) {
      _coupleProfiles[userId] = profile;
      state = state.copyWith(coupleProfile: profile, needsOnboarding: false, error: e.message);
    } catch (e, stackTrace) {
      AppLogger.error('Couple profile save failed, keeping local copy only', e, stackTrace);
      _coupleProfiles[userId] = profile;
      state = state.copyWith(
        coupleProfile: profile,
        needsOnboarding: false,
        error: 'Could not save your profile. Please try again.',
      );
    }
  }

  void completeVendorOnboarding() {
    state = state.copyWith(needsOnboarding: false);
  }

  /// Called once a vendor's profile has actually been saved to the backend
  /// (see vendor_onboarding_screen.dart), so the rest of the app sees it
  /// immediately without a refetch.
  void setVendorProfile(VendorProfile profile) {
    final userId = state.user?.id;
    if (userId != null) _vendorProfiles[userId] = profile;
    state = state.copyWith(vendorProfile: profile);
  }

  /// Called once a couple's photo has been saved to the backend, so the rest
  /// of the app sees it immediately without a refetch.
  void setCoupleProfile(CoupleProfile profile) {
    final userId = state.user?.id;
    if (userId != null) _coupleProfiles[userId] = profile;
    state = state.copyWith(coupleProfile: profile);
  }

  /// Mails a fresh confirmation link to the signed-in address.
  ///
  /// Returns whether it actually went out, so the verify screen only starts
  /// its resend cooldown on success — a failed send that still locked the
  /// button for a minute would be the worst of both.
  Future<bool> resendVerificationEmail() async {
    final token = _accessToken;
    if (token == null) {
      state = state.copyWith(error: 'Please log in again to resend that email.');
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resendVerificationEmail(token);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: describeError(e));
      return false;
    }
  }

  /// Redeems a confirmation link's token. On success the cached [User] is
  /// flipped to verified in place rather than refetched — the caller may not
  /// even be the account holder's session (the link opens wherever their mail
  /// client sends it), so there is not always a session to refetch with.
  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.verifyEmail(token);
      final user = state.user;
      state = state.copyWith(
        isLoading: false,
        user: user?.copyWith(isVerified: true),
      );
      return true;
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: describeError(e));
      return false;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: describeError(e));
    }
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resetPassword(token: token, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: describeError(e));
    }
  }

  Future<void> logout() async {
    await tokenService.clearTokens();
    _accessToken = null;
    state = const AuthState();
    // None of the per-account providers auto-dispose, so without this the next
    // account signed in on this device renders the previous one's bookings,
    // budget, invitations and profile.
    invalidateSessionScopedProviders(_ref);
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(AuthService.instance, ref),
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final coupleProfileProvider = Provider<CoupleProfile?>((ref) {
  return ref.watch(authProvider).coupleProfile;
});

final vendorProfileProvider = Provider<VendorProfile?>((ref) {
  return ref.watch(authProvider).vendorProfile;
});

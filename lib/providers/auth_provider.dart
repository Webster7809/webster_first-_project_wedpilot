import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../core/services/couple_profile_service.dart';
import '../core/services/token_service.dart';
import '../core/services/vendor_api_service.dart';
import '../models/user.dart';
import '../models/couple_profile.dart';
import '../models/vendor_profile.dart';

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
  AuthNotifier(this._authService) : super(const AuthState());

  final AuthService _authService;

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
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Could not reach the server. Please try again.');
    }
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
      );
      await _applyAuthResult(result, forceOnboarding: true);
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Could not reach the server. Please try again.');
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

    final user = result.user;
    CoupleProfile? coupleProfile;
    VendorProfile? vendorProfile;
    bool needsOnboarding;

    if (user.role == UserRole.couple) {
      coupleProfile = await _fetchCoupleProfileGracefully(result.accessToken);
      if (coupleProfile != null) _coupleProfiles[user.id] = coupleProfile;
      needsOnboarding = coupleProfile == null;
    } else if (user.role == UserRole.vendor) {
      vendorProfile = await _fetchVendorProfileGracefully(result.accessToken);
      if (vendorProfile != null) _vendorProfiles[user.id] = vendorProfile;
      needsOnboarding = forceOnboarding || vendorProfile == null;
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

  /// Fetches the couple's saved profile, treating any network/server failure
  /// the same as "no profile yet" rather than blocking login/restore.
  Future<CoupleProfile?> _fetchCoupleProfileGracefully(String accessToken) async {
    try {
      return await CoupleProfileService.instance.fetchProfile(accessToken);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the vendor's saved profile, treating any network/server failure
  /// the same as "no profile yet" rather than blocking login/restore. This is
  /// the source of truth for whether a vendor still needs onboarding — an
  /// existing vendor with a saved profile always skips straight to their
  /// dashboard, on any device.
  Future<VendorProfile?> _fetchVendorProfileGracefully(String accessToken) async {
    try {
      return await VendorApiService.instance.fetchMyProfile(accessToken);
    } catch (_) {
      return null;
    }
  }

  /// Restores a session on app cold-start after the stored access token was
  /// validated against the backend (see sessionRestoreProvider).
  Future<void> restoreSession(User user, {required String accessToken}) async {
    _accessToken = accessToken;
    CoupleProfile? coupleProfile;
    VendorProfile? vendorProfile;
    bool needsOnboarding;

    if (user.role == UserRole.couple) {
      coupleProfile = await _fetchCoupleProfileGracefully(accessToken);
      if (coupleProfile != null) _coupleProfiles[user.id] = coupleProfile;
      needsOnboarding = coupleProfile == null;
    } else if (user.role == UserRole.vendor) {
      vendorProfile = await _fetchVendorProfileGracefully(accessToken);
      if (vendorProfile != null) _vendorProfiles[user.id] = vendorProfile;
      needsOnboarding = vendorProfile == null;
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
    } catch (e) {
      // ignore: avoid_print
      print('[updateCoupleProfile] failed to save, keeping local copy only: $e');
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

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
  }

  Future<void> logout() async {
    await tokenService.clearTokens();
    _accessToken = null;
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(AuthService.instance),
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

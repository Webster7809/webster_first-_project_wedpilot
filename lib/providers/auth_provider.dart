import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Admin credentials — known only to the system administrator.
const _kAdminEmail = 'admin@wedpilot.app';
const _kAdminPassword = 'W3dP!l0t#Adm1n';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    final normalised = email.toLowerCase().trim();

    if (normalised.contains('admin')) {
      if (normalised != _kAdminEmail || password != _kAdminPassword) {
        state = state.copyWith(isLoading: false, error: 'Invalid credentials.');
        return;
      }
    }

    UserRole role = UserRole.couple;
    if (normalised.contains('vendor')) role = UserRole.vendor;
    if (normalised == _kAdminEmail) role = UserRole.admin;

    final user = User(
      id: 'user-001',
      email: email,
      name: role == UserRole.vendor ? 'Mukuba Gardens' : 'Chanda',
      role: role,
      isVerified: true,
      createdAt: DateTime.now(),
    );

    CoupleProfile? coupleProfile;
    VendorProfile? vendorProfile;

    if (role == UserRole.couple) {
      coupleProfile = CoupleProfile(
        id: 'profile-001',
        userId: 'user-001',
        weddingDate: DateTime(2026, 9, 12),
        location: 'Ndola, Copperbelt',
        guestCount: 150,
        styleTags: ['White wedding', 'Flexible'],
        totalBudget: 85000,
        currency: 'ZMW',
        partnerName: 'Mwila',
      );
    } else if (role == UserRole.vendor) {
      vendorProfile = VendorProfile(
        id: 'vendor-001',
        userId: 'user-001',
        businessName: 'Mukuba Gardens',
        description:
            'Spacious garden venue seating up to 300 guests, with backup generator, parking for 80 cars and an in-house decor team. Located 10 minutes from Ndola town centre.',
        category: 'Venue',
        location: 'Ndola, Copperbelt',
        latitude: -12.9587,
        longitude: 28.6366,
        tier: VendorTier.premium,
        verificationStatus: VerificationStatus.verified,
        rating: 4.9,
        reviewCount: 42,
        compositeScore: 95.0,
        services: [
          VendorService(
            id: 's-v01',
            vendorId: 'vendor-001',
            title: 'Open Air Garden Package',
            description: 'Full venue rental up to 300 guests',
            priceMin: 28000,
            priceMax: 35000,
            unit: 'event',
          ),
        ],
      );
    }

    state = state.copyWith(
      user: user,
      coupleProfile: coupleProfile,
      vendorProfile: vendorProfile,
      isLoading: false,
    );
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
    await Future.delayed(const Duration(milliseconds: 800));
    final user = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: partner1Name,
      role: role,
      isVerified: false,
      createdAt: DateTime.now(),
    );
    CoupleProfile? coupleProfile;
    if (role == UserRole.couple && partner2Name != null) {
      coupleProfile = CoupleProfile(
        id: 'profile-${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        currency: 'ZMW',
        partnerName: partner2Name,
      );
    }
    state = state.copyWith(
      user: user,
      coupleProfile: coupleProfile,
      isLoading: false,
      needsOnboarding: true,
    );
  }

  void updateCoupleProfile({
    required List<String> selectedItems,
    required double budget,
    required String weddingStyle,
    required String weddingClass,
    required int guestCount,
    required String location,
  }) {
    final profile = CoupleProfile(
      id: state.coupleProfile?.id ?? 'profile-${DateTime.now().millisecondsSinceEpoch}',
      userId: state.user?.id ?? '',
      partnerName: state.coupleProfile?.partnerName,
      location: location.isNotEmpty ? location : null,
      guestCount: guestCount > 0 ? guestCount : null,
      styleTags: [weddingStyle, weddingClass, ...selectedItems],
      totalBudget: budget > 0 ? budget : null,
      currency: 'ZMW',
    );
    state = state.copyWith(coupleProfile: profile, needsOnboarding: false);
  }

  void completeVendorOnboarding() {
    state = state.copyWith(needsOnboarding: false);
  }

  Future<void> logout() async {
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
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

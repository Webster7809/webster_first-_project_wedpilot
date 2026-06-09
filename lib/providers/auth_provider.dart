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

  const AuthState({
    this.user,
    this.coupleProfile,
    this.vendorProfile,
    this.isLoading = false,
    this.error,
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
  }) =>
      AuthState(
        user: user ?? this.user,
        coupleProfile: coupleProfile ?? this.coupleProfile,
        vendorProfile: vendorProfile ?? this.vendorProfile,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    // Determine role by email for demo
    UserRole role = UserRole.couple;
    if (email.contains('vendor')) role = UserRole.vendor;
    if (email.contains('admin')) role = UserRole.admin;

    final user = User(
      id: 'user-001',
      email: email,
      name: role == UserRole.vendor ? 'Blossom Photography' : 'Alex & Jordan',
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
        weddingDate: DateTime.now().add(const Duration(days: 180)),
        location: 'New York, NY',
        guestCount: 120,
        styleTags: ['Romantic', 'Garden'],
        totalBudget: 30000,
        currency: 'USD',
        partnerName: 'Jordan',
      );
    } else if (role == UserRole.vendor) {
      vendorProfile = VendorProfile(
        id: 'vendor-001',
        userId: 'user-001',
        businessName: 'Blossom Photography',
        description: 'Award-winning wedding photography studio',
        category: 'Photography',
        location: 'New York, NY',
        tier: VendorTier.pro,
        verificationStatus: VerificationStatus.verified,
        rating: 4.8,
        reviewCount: 47,
        compositeScore: 87.5,
      );
    }

    state = state.copyWith(
      user: user,
      coupleProfile: coupleProfile,
      vendorProfile: vendorProfile,
      isLoading: false,
    );
  }

  Future<void> register(String name, String email, String password, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
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

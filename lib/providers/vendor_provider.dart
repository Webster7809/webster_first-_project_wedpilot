import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../core/fixtures/vendor_fixtures.dart';
import 'auth_provider.dart';
import 'vendor_own_provider.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'Photography');

final selectedServiceCategoriesProvider = StateProvider<List<String>>((ref) => []);

final vendorSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Shared vendor registry — mockVendors merged with the live vendor profile ──

final vendorRegistryProvider = Provider<List<VendorProfile>>((ref) {
  final ownProfile = ref.watch(vendorOwnProvider).profile;
  if (ownProfile == null) return mockVendors;

  final idx = mockVendors.indexWhere((v) => v.id == ownProfile.id);
  if (idx == -1) return [...mockVendors, ownProfile];

  return [
    for (int i = 0; i < mockVendors.length; i++)
      if (i == idx) ownProfile else mockVendors[i],
  ];
});

// ── Location-aware vendor list ──────────────────────────────────────────────

final vendorListProvider = FutureProvider.family<List<VendorProfile>, String>(
  (ref, category) async {
    final coupleProfile = ref.watch(coupleProfileProvider);
    final registry = ref.watch(vendorRegistryProvider);
    await Future.delayed(const Duration(milliseconds: 600));

    final filtered = registry.where((v) => v.category == category).toList();

    final location = coupleProfile?.location;
    if (location == null || location.isEmpty) return filtered;

    final coords = coordsForLocation(location);
    if (coords == null) return filtered;

    filtered.sort((a, b) {
      final scoreA = vendorMatchScore(a, coords[0], coords[1]);
      final scoreB = vendorMatchScore(b, coords[0], coords[1]);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  },
);

final vendorDetailProvider = FutureProvider.family<VendorProfile, String>(
  (ref, vendorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return mockVendors.firstWhere(
      (v) => v.id == vendorId,
      orElse: () => mockVendors.isNotEmpty
          ? mockVendors.first
          : throw StateError('No vendor found with id $vendorId'),
    );
  },
);

final recommendedVendorsProvider = Provider<List<VendorProfile>>((ref) {
  final selectedServices = ref.watch(selectedServiceCategoriesProvider);
  if (selectedServices.isEmpty) return mockVendors.take(4).toList();
  return mockVendors
      .where((v) => selectedServices.contains(v.category))
      .toList();
});

final allVendorsProvider = Provider<List<VendorProfile>>((ref) => mockVendors);

// ── Wishlist ────────────────────────────────────────────────────────────────

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<String>>(
  (ref) => WishlistNotifier(),
);

class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier() : super([]);

  void toggle(String vendorId) {
    if (state.contains(vendorId)) {
      state = state.where((id) => id != vendorId).toList();
    } else {
      state = [...state, vendorId];
    }
  }

  bool isWishlisted(String vendorId) => state.contains(vendorId);
}

// ── Vendor Ratings ──────────────────────────────────────────────────────────

final vendorRatingsProvider =
    StateNotifierProvider<VendorRatingNotifier, Map<String, int>>(
  (ref) => VendorRatingNotifier(),
);

class VendorRatingNotifier extends StateNotifier<Map<String, int>> {
  VendorRatingNotifier() : super(const {});

  void rate(String vendorId, int stars) {
    assert(stars >= 1 && stars <= 5);
    state = {...state, vendorId: stars};
  }

  void unrate(String vendorId) {
    state = Map.from(state)..remove(vendorId);
  }

  int? getRating(String vendorId) => state[vendorId];
}

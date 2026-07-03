import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../core/services/vendor_api_service.dart';
import '../core/state/resource.dart';
import '../core/utils/geo_utils.dart';
import 'auth_provider.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'Photography');

final selectedServiceCategoriesProvider = StateProvider<List<String>>((ref) => []);

final vendorSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Location-aware vendor list ──────────────────────────────────────────────

final vendorListProvider = FutureProvider.family<List<VendorProfile>, String>(
  (ref, category) async {
    final token = ref.watch(authProvider.notifier).accessToken;
    if (token == null) return [];

    final coupleProfile = ref.watch(coupleProfileProvider);
    final vendors = await VendorApiService.instance.fetchVendors(token, category: category);

    final location = coupleProfile?.location;
    if (location == null || location.isEmpty) return vendors;

    final coords = coordsForLocation(location);
    if (coords == null) return vendors;

    final sorted = [...vendors];
    sorted.sort((a, b) {
      final scoreA = vendorMatchScore(a, coords[0], coords[1]);
      final scoreB = vendorMatchScore(b, coords[0], coords[1]);
      return scoreB.compareTo(scoreA);
    });
    return sorted;
  },
);

final vendorDetailProvider = FutureProvider.family<VendorProfile, String>(
  (ref, vendorId) async {
    final token = ref.watch(authProvider.notifier).accessToken;
    if (token == null) throw StateError('Not signed in.');
    return VendorApiService.instance.fetchVendorDetail(token, vendorId);
  },
);

final recommendedVendorsProvider = FutureProvider<List<VendorProfile>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  final selectedServices = ref.watch(selectedServiceCategoriesProvider);
  final allVendors = await VendorApiService.instance.fetchVendors(token);
  if (selectedServices.isEmpty) return allVendors.take(4).toList();
  return allVendors.where((v) => selectedServices.contains(v.category)).toList();
});

final allVendorsProvider = FutureProvider<List<VendorProfile>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return VendorApiService.instance.fetchVendors(token);
});

// ── Wishlist ────────────────────────────────────────────────────────────────
//
// Exposed as a plain List<String> (empty by default) rather than a
// Resource-wrapped type, since every consumer just needs `.contains(id)`
// membership checks — the dedicated wishlist screen already treats an empty
// list as a legitimate empty state. `status` is available separately for
// screens that need to trigger the initial load exactly once.

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<String>>(
  (ref) => WishlistNotifier(ref),
);

class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier(this._ref) : super([]);

  final Ref _ref;
  ResourceStatus status = ResourceStatus.initial;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  Future<void> loadWishlist() async {
    final token = _token;
    if (token == null) return;
    status = ResourceStatus.loading;
    try {
      state = await VendorApiService.instance.fetchWishlist(token);
      status = ResourceStatus.ready;
    } catch (_) {
      status = ResourceStatus.error;
    }
  }

  Future<void> toggle(String vendorId) async {
    final token = _token;
    if (token == null) return;
    final wasWishlisted = state.contains(vendorId);

    // Optimistic update, rolled back if the API call fails.
    state = wasWishlisted
        ? state.where((id) => id != vendorId).toList()
        : [...state, vendorId];

    try {
      if (wasWishlisted) {
        await VendorApiService.instance.removeFromWishlist(token, vendorId);
      } else {
        await VendorApiService.instance.addToWishlist(token, vendorId);
      }
    } catch (_) {
      // Roll back to the prior state on failure.
      state = wasWishlisted
          ? [...state, vendorId]
          : state.where((id) => id != vendorId).toList();
    }
  }

  bool isWishlisted(String vendorId) => state.contains(vendorId);
}

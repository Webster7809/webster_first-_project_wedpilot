import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../core/constants/app_constants.dart';
import '../core/services/vendor_api_service.dart';
import '../core/state/resource.dart';
import '../core/utils/geo_utils.dart';
import 'auth_provider.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'Photography');

final selectedServiceCategoriesProvider = StateProvider<List<String>>((ref) => []);

// ── Location-aware vendor list ──────────────────────────────────────────────

/// Passing the literal 'All' skips the category filter entirely, returning
/// every verified vendor across categories instead of just one.
const kAllVendorCategories = 'All';

final vendorListProvider = FutureProvider.family<List<VendorProfile>, String>(
  (ref, category) async {
    final token = ref.watch(authProvider.notifier).accessToken;
    if (token == null) return [];

    final coupleProfile = ref.watch(coupleProfileProvider);
    // fetchAllVendors, not fetchVendors — the plain call silently caps at the
    // backend's default page size (see its doc comment), so browsing 'All'
    // or a category with more vendors than one page would quietly drop
    // everything past page 1 instead of showing the full directory.
    final vendors = await VendorApiService.instance.fetchAllVendors(
      token,
      category: category == kAllVendorCategories ? null : category,
    );

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

/// Category-scoped vendor fetch — narrower than [allVendorsProvider] (every
/// vendor, every category); this fetches only the categories asked for,
/// matching what vendorMatchValidationProvider requests from the backend via
/// GET /api/vendors?category_in=... (see routes/vendors.js). A distinct,
/// overridable provider rather than a raw [VendorApiService] call inline in
/// vendorMatchValidationProvider, so tests can substitute fixed vendor data
/// here without a real access token or network call — see
/// couple_planning_screen_test.dart.
final vendorPoolProvider =
    FutureProvider.family<List<VendorProfile>, List<String>>(
  (ref, categories) async {
    final token = ref.watch(authProvider.notifier).accessToken;
    if (token == null) return const [];
    return VendorApiService.instance.fetchAllVendors(
      token,
      categories: categories.isEmpty ? null : categories,
    );
  },
);

/// Backs the vendor discovery screen's typeahead search — a network call per
/// query, so `.autoDispose` (the only such provider in this file) lets
/// Riverpod garbage-collect the cache entry for each distinct search string
/// once nothing watches it anymore, instead of retaining one instance per
/// keystroke ever typed for the life of the app.
final vendorSearchResultsProvider = FutureProvider.autoDispose
    .family<List<VendorProfile>, ({String category, String search})>(
  (ref, params) async {
    final token = ref.watch(authProvider.notifier).accessToken;
    if (token == null || params.search.isEmpty) return [];
    return VendorApiService.instance.fetchVendors(
      token,
      category: params.category == kAllVendorCategories ? null : params.category,
      search: params.search,
    );
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
  // fetchAllVendors — this filters by selectedServices client-side below, so
  // a plain fetchVendors() call (capped at the backend's default page size)
  // would silently miss every vendor outside whatever page happened to come
  // back, making entire categories look empty even though they aren't.
  final allVendors = await VendorApiService.instance.fetchAllVendors(token);
  if (selectedServices.isEmpty) return allVendors.take(4).toList();
  return allVendors.where((v) => selectedServices.contains(v.category)).toList();
});

// WedPilot's curated vendor catalog (genuine High-Class/Flexible earners for
// every category, so the AI matcher always has real premium/mid-tier options
// to find) used to be appended here as frontend-only mock data. It's now
// seeded as real rows in the backend (see backend/scripts/seedCuratedVendors.js)
// so those vendors also work everywhere else — discovery, dashboard, detail
// view, wishlist, booking, feedback — not just AI matching. This provider is
// now just the real backend vendor list, nothing appended client-side.
final allVendorsProvider = FutureProvider<List<VendorProfile>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return VendorApiService.instance.fetchAllVendors(token);
});

/// Largest guest capacity any vendor anywhere in the system has stated,
/// across every category and location. This is a deliberately coarse,
/// system-wide gate — not a substitute for the precise, category/location
/// -scoped capacity check that already runs in vendorMatchValidationProvider
/// (Step 3b/3c) — used only so couple_planning_screen.dart can reject a
/// guest count nobody in the whole system could ever serve immediately on
/// entry, instead of three wizard steps later. Null when no vendor has
/// stated a capacity yet, in which case the gate must be skipped entirely:
/// unstated capacity is neutral, never a reason to block (same rule as
/// VendorProfile.canServeGuestCount).
final systemMaxGuestCapacityProvider = FutureProvider<int?>((ref) async {
  final vendors = await ref.watch(allVendorsProvider.future);
  final stated = vendors.map((v) => v.maxGuestCapacity).whereType<int>();
  if (stated.isEmpty) return null;
  return stated.reduce((a, b) => a > b ? a : b);
});

/// Union of WedPilot's built-in vendor categories and every category real
/// vendors have registered under — so a vendor signing up in a brand-new
/// category makes it selectable for couples automatically, without an app
/// release. Built-ins keep their curated order; vendor-registered extras
/// follow alphabetically. Falls back to just the built-ins if the vendor
/// directory can't be reached, so category selection never blocks on it.
final availableVendorCategoriesProvider =
    FutureProvider<List<String>>((ref) async {
  List<VendorProfile> vendors;
  try {
    vendors = await ref.watch(allVendorsProvider.future);
  } catch (_) {
    vendors = const [];
  }
  final seen = {
    for (final c in AppConstants.vendorCategories) c.toLowerCase(),
  };
  final extras = <String>[];
  for (final v in vendors) {
    final c = v.category.trim();
    if (c.isNotEmpty && seen.add(c.toLowerCase())) extras.add(c);
  }
  extras.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [...AppConstants.vendorCategories, ...extras];
});

// Resolves the couple's saved vendor IDs into full VendorProfile objects by
// fetching each one individually rather than paging through the directory.
final wishlistedVendorsProvider = FutureProvider<List<VendorProfile>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  final wishlistIds = ref.watch(wishlistProvider);
  if (token == null || wishlistIds.isEmpty) return [];

  final results = await Future.wait(
    wishlistIds.map((id) async {
      try {
        return await VendorApiService.instance.fetchVendorDetail(token, id);
      } catch (_) {
        return null;
      }
    }),
  );
  return results.whereType<VendorProfile>().toList();
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

  /// Returns the server error message on failure (after rolling the
  /// optimistic update back), or null on success — the icon flipping and
  /// then silently flipping back within the same frame used to look
  /// identical to "nothing happened" with no way to tell why.
  Future<String?> toggle(String vendorId) async {
    final token = _token;
    if (token == null) return 'Please sign in to save vendors.';
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
      return null;
    } on VendorApiException catch (e) {
      // Roll back to the prior state on failure.
      state = wasWishlisted
          ? [...state, vendorId]
          : state.where((id) => id != vendorId).toList();
      return e.message;
    } catch (_) {
      state = wasWishlisted
          ? [...state, vendorId]
          : state.where((id) => id != vendorId).toList();
      return 'Could not save this vendor. Please try again.';
    }
  }

  bool isWishlisted(String vendorId) => state.contains(vendorId);
}

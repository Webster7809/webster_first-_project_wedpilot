import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import 'auth_provider.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'Photography');

final selectedServiceCategoriesProvider = StateProvider<List<String>>((ref) => []);

final vendorSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Location-aware vendor list ──────────────────────────────────────────────

final vendorListProvider = FutureProvider.family<List<VendorProfile>, String>(
  (ref, category) async {
    // Watch BEFORE any await so Riverpod tracks the dependency correctly
    final coupleProfile = ref.watch(coupleProfileProvider);

    await Future.delayed(const Duration(milliseconds: 600));

    final filtered = _mockVendors.where((v) => v.category == category).toList();

    final location = coupleProfile?.location;
    if (location == null || location.isEmpty) return filtered;

    final coords = _coordsForLocation(location);
    if (coords == null) return filtered;

    // Sort by combined score: 50% reputation + 50% proximity
    filtered.sort((a, b) {
      final scoreA = _matchScore(a, coords[0], coords[1]);
      final scoreB = _matchScore(b, coords[0], coords[1]);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  },
);

final vendorDetailProvider = FutureProvider.family<VendorProfile, String>(
  (ref, vendorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockVendors.firstWhere((v) => v.id == vendorId,
        orElse: () => _mockVendors.first);
  },
);

final recommendedVendorsProvider = Provider<List<VendorProfile>>((ref) {
  final selectedServices = ref.watch(selectedServiceCategoriesProvider);
  if (selectedServices.isEmpty) {
    return _mockVendors.take(4).toList();
  }
  return _mockVendors
      .where((vendor) => selectedServices.contains(vendor.category))
      .toList();
});

// ── Picked Vendors ──────────────────────────────────────────────────────────

final pickedVendorsProvider =
    StateNotifierProvider<PickedVendorsNotifier, Set<String>>(
  (ref) => PickedVendorsNotifier(),
);

class PickedVendorsNotifier extends StateNotifier<Set<String>> {
  PickedVendorsNotifier() : super(const {});

  void toggle(String vendorId) {
    if (state.contains(vendorId)) {
      state = Set.from(state)..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }
  }

  bool isPicked(String vendorId) => state.contains(vendorId);
}

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

// ── Vendor ratings (couple can rate 1–5 stars, and remove rating) ───────────

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

// ── Location matching helpers ───────────────────────────────────────────────

// Returns [lat, lon] for a known city name, or null if not found.
List<double>? _coordsForLocation(String location) {
  final normalized = location.toLowerCase().trim();
  for (final entry in _cityCoordinates.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

double _matchScore(VendorProfile vendor, double coupleLat, double coupleLon) {
  final reputation = vendor.compositeScore / 100.0;

  if (vendor.latitude == null || vendor.longitude == null) {
    return reputation * 0.5;
  }

  final distKm =
      _haversineKm(coupleLat, coupleLon, vendor.latitude!, vendor.longitude!);
  const maxDistKm = 300.0;
  final proximity = (1.0 - distKm / maxDistKm).clamp(0.0, 1.0);

  return reputation * 0.5 + proximity * 0.5;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRad(double deg) => deg * pi / 180;

// City → [lat, lon].  Keys are lowercase substrings — first match wins.
const Map<String, List<double>> _cityCoordinates = {
  // USA
  'new york': [40.7128, -74.0060],
  'brooklyn': [40.6782, -73.9442],
  'manhattan': [40.7831, -73.9712],
  'long island': [40.7891, -73.1350],
  'los angeles': [34.0522, -118.2437],
  'chicago': [41.8781, -87.6298],
  'houston': [29.7604, -95.3698],
  'miami': [25.7617, -80.1918],
  'atlanta': [33.7490, -84.3880],
  'dallas': [32.7767, -96.7970],
  // UK
  'london': [51.5074, -0.1278],
  'manchester': [53.4808, -2.2426],
  'birmingham': [52.4862, -1.8904],
  // Africa
  'nairobi': [-1.2921, 36.8219],
  'lusaka': [-15.4167, 28.2833],
  'johannesburg': [-26.2041, 28.0473],
  'cape town': [-33.9249, 18.4241],
  'lagos': [6.5244, 3.3792],
  'accra': [5.6037, -0.1870],
  'kampala': [0.3476, 32.5825],
  'dar es salaam': [-6.7924, 39.2083],
  'abuja': [9.0765, 7.3986],
  'kigali': [-1.9441, 30.0619],
  'harare': [-17.8252, 31.0335],
  'blantyre': [-15.7861, 35.0058],
  'ndola': [-12.9587, 28.6366],
  'kitwe': [-12.8024, 28.2132],
  // Canada / Australia
  'toronto': [43.6532, -79.3832],
  'sydney': [-33.8688, 151.2093],
  'melbourne': [-37.8136, 144.9631],
  // Europe
  'paris': [48.8566, 2.3522],
  'dubai': [25.2048, 55.2708],
};

// ── Mock vendor data ────────────────────────────────────────────────────────

final List<VendorProfile> _mockVendors = [
  VendorProfile(
    id: 'v-001',
    userId: 'u-001',
    businessName: 'Blossom Photography',
    description:
        'Award-winning wedding photography with a romantic, editorial style. Over 200 weddings captured.',
    category: 'Photography',
    location: 'New York, NY',
    latitude: 40.7128,
    longitude: -74.0060,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Romantic', 'Editorial', 'Modern'],
    rating: 4.9,
    reviewCount: 87,
    compositeScore: 94.2,
    services: [
      VendorService(
          id: 's-001',
          vendorId: 'v-001',
          title: 'Full Day Coverage',
          description: '10 hours of coverage',
          priceMin: 3500,
          priceMax: 5000,
          unit: 'package'),
      VendorService(
          id: 's-002',
          vendorId: 'v-001',
          title: 'Half Day Coverage',
          description: '6 hours of coverage',
          priceMin: 2200,
          priceMax: 3200,
          unit: 'package'),
    ],
  ),
  VendorProfile(
    id: 'v-002',
    userId: 'u-002',
    businessName: 'Golden Lens Studio',
    description:
        'Candid, documentary-style wedding photography that tells your love story authentically.',
    category: 'Photography',
    location: 'Brooklyn, NY',
    latitude: 40.6782,
    longitude: -73.9442,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Candid', 'Documentary', 'Boho'],
    rating: 4.7,
    reviewCount: 52,
    compositeScore: 88.5,
    services: [
      VendorService(
          id: 's-003',
          vendorId: 'v-002',
          title: 'Wedding Package A',
          description: '8 hours, 2 photographers',
          priceMin: 2800,
          priceMax: 4000,
          unit: 'package'),
    ],
  ),
  VendorProfile(
    id: 'v-003',
    userId: 'u-003',
    businessName: 'The Garden Venue',
    description:
        'An enchanting outdoor wedding venue with manicured gardens, fountain, and reception hall.',
    category: 'Venue',
    location: 'Long Island, NY',
    latitude: 40.7891,
    longitude: -73.1350,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Garden', 'Romantic', 'Outdoor'],
    rating: 4.8,
    reviewCount: 134,
    compositeScore: 91.0,
    services: [
      VendorService(
          id: 's-004',
          vendorId: 'v-003',
          title: 'Full Venue Rental',
          description: 'Up to 200 guests, full day',
          priceMin: 8000,
          priceMax: 15000,
          unit: 'day'),
    ],
  ),
  VendorProfile(
    id: 'v-004',
    userId: 'u-004',
    businessName: 'Culinary Bliss Catering',
    description:
        'Farm-to-table wedding catering with customizable menus and professional service staff.',
    category: 'Catering',
    location: 'New York, NY',
    latitude: 40.7580,
    longitude: -73.9855,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Modern', 'Farm-to-Table'],
    rating: 4.6,
    reviewCount: 68,
    compositeScore: 85.3,
    services: [
      VendorService(
          id: 's-005',
          vendorId: 'v-004',
          title: 'Per Person Package',
          description: 'Includes appetizers, main, dessert',
          priceMin: 85,
          priceMax: 150,
          unit: 'per person'),
    ],
  ),
  VendorProfile(
    id: 'v-005',
    userId: 'u-005',
    businessName: 'Petal & Bloom Floristry',
    description:
        'Luxury floral designs that transform your wedding vision into a breathtaking reality.',
    category: 'Floristry',
    location: 'Manhattan, NY',
    latitude: 40.7831,
    longitude: -73.9712,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Romantic', 'Luxury', 'Garden'],
    rating: 4.9,
    reviewCount: 43,
    compositeScore: 92.1,
    services: [
      VendorService(
          id: 's-006',
          vendorId: 'v-005',
          title: 'Full Floral Package',
          description: 'Ceremony + reception florals',
          priceMin: 3000,
          priceMax: 8000,
          unit: 'package'),
    ],
  ),
  VendorProfile(
    id: 'v-006',
    userId: 'u-006',
    businessName: 'Sweet Moments Cake Studio',
    description:
        'Custom wedding cakes and dessert tables crafted with artistic detail and exceptional flavors.',
    category: 'Cake',
    location: 'Queens, NY',
    latitude: 40.7282,
    longitude: -73.7949,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Modern', 'Elegant'],
    rating: 4.7,
    reviewCount: 91,
    compositeScore: 86.8,
    services: [
      VendorService(
          id: 's-007',
          vendorId: 'v-006',
          title: 'Custom Wedding Cake',
          description: 'Per serving pricing',
          priceMin: 6,
          priceMax: 15,
          unit: 'per serving'),
    ],
  ),
];

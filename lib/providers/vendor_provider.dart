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

/// Full vendor catalogue — used by report generation and vendor matching logic.
final allVendorsProvider = Provider<List<VendorProfile>>((ref) => _mockVendors);

// ── Budget Class ────────────────────────────────────────────────────────────

enum BudgetClass {
  highClass,
  flexible,
  budgetFriendly;

  String get displayName => switch (this) {
    BudgetClass.highClass => 'High Class',
    BudgetClass.flexible => 'Flexible',
    BudgetClass.budgetFriendly => 'Budget-Friendly',
  };

  String get icon => switch (this) {
    BudgetClass.highClass => '👑',
    BudgetClass.flexible => '⚖️',
    BudgetClass.budgetFriendly => '💚',
  };

  String get subtitle => switch (this) {
    BudgetClass.highClass => 'Luxury & Premium Only',
    BudgetClass.flexible => 'Best Value, All Tiers',
    BudgetClass.budgetFriendly => 'Affordable & Quality',
  };

  String get description => switch (this) {
    BudgetClass.highClass =>
      'Exclusive curation of premium vendors — top-rated, luxury-tier, celebrated for extraordinary weddings.',
    BudgetClass.flexible =>
      'AI-optimised mix of top-value vendors across all tiers — the intelligent balanced recommendation.',
    BudgetClass.budgetFriendly =>
      'Quality-controlled affordable vendors — proven reliability without compromising your wedding vision.',
  };

  List<String> get features => switch (this) {
    BudgetClass.highClass => [
      '4.5★ or higher only',
      'Premium tier vendors',
      'Top portfolio & brand reputation',
    ],
    BudgetClass.flexible => [
      'Best quality-to-price ratio',
      'All tiers considered',
      'Intelligent AI-balanced mix',
    ],
    BudgetClass.budgetFriendly => [
      '3.5★ minimum quality floor',
      'Affordable pricing tier',
      'Trusted value & reliability',
    ],
  };
}

/// Persists the couple's chosen budget class across the wizard and recommendations.
final budgetClassProvider = StateProvider<BudgetClass>((ref) => BudgetClass.flexible);

/// AI-ranked vendor recommendations driven by [budgetClassProvider].
/// Re-evaluates automatically whenever the budget class or selected categories change.
final aiRecommendedVendorsProvider = FutureProvider<List<VendorMatch>>((ref) async {
  final budgetClass = ref.watch(budgetClassProvider);
  final categories = ref.watch(selectedServiceCategoriesProvider);
  final coupleProfile = ref.watch(coupleProfileProvider);

  await Future.delayed(const Duration(milliseconds: 900));

  final coords = coupleProfile?.location != null
      ? _coordsForLocation(coupleProfile!.location!)
      : null;

  return _AiEngine.recommend(
    vendors: _mockVendors,
    budgetClass: budgetClass,
    categories: categories,
    coupleLat: coords?[0],
    coupleLon: coords?[1],
  );
});

// ── AI Recommendation Engine ────────────────────────────────────────────────

class _AiEngine {
  _AiEngine._();

  static const double _minRatingHighClass = 4.5;
  static const double _minRatingBudget = 3.5;
  static const double _minRatingFlexible = 3.0;
  static const double _maxReviews = 200.0;

  static List<VendorMatch> recommend({
    required List<VendorProfile> vendors,
    required BudgetClass budgetClass,
    required List<String> categories,
    double? coupleLat,
    double? coupleLon,
  }) {
    // 1. Category filter (empty → all categories)
    var pool = categories.isEmpty
        ? vendors
        : vendors.where((v) => categories.contains(v.category)).toList();

    // 2. Budget-class eligibility gate
    pool = pool.where((v) => _eligible(v, budgetClass)).toList();

    // 3. Score each vendor
    final scored = pool.map((v) {
      final rep = _reputationScore(v);
      final loc = _locationScore(v, coupleLat, coupleLon);
      final val = _valueScore(v, budgetClass);
      final fin = _finalScore(rep, loc, val, budgetClass);
      return _ScoredVendor(vendor: v, reputation: rep, location: loc, value: val, finalScore: fin);
    }).toList();

    // 4. Sort descending by final score (stable)
    scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    // 5. Build VendorMatch with per-category rank + AI reasoning
    final catTotal = <String, int>{};
    for (final s in scored) {
      catTotal[s.vendor.category] = (catTotal[s.vendor.category] ?? 0) + 1;
    }
    final catRank = <String, int>{};

    return scored.map((s) {
      final rank = (catRank[s.vendor.category] ?? 0) + 1;
      catRank[s.vendor.category] = rank;
      return VendorMatch(
        vendorId: s.vendor.id,
        vendor: s.vendor,
        finalScore: s.finalScore,
        reputationScore: s.reputation,
        budgetScore: s.value,
        locationScore: s.location,
        availabilityScore: 1.0,
        reasoning: _reason(s.vendor, budgetClass, rank),
        rankInCategory: rank,
        totalInCategory: catTotal[s.vendor.category]!,
      );
    }).toList();
  }

  // ── Eligibility gates ───────────────────────────────────────────────────────

  static bool _eligible(VendorProfile v, BudgetClass bc) {
    final r = v.rating ?? 0;
    return switch (bc) {
      BudgetClass.highClass =>
        v.priceTier == VendorPriceTier.high && r >= _minRatingHighClass,
      BudgetClass.flexible => r >= _minRatingFlexible,
      BudgetClass.budgetFriendly =>
        v.priceTier != VendorPriceTier.high && r >= _minRatingBudget,
    };
  }

  // ── Component scores (0–1) ──────────────────────────────────────────────────

  static double _reputationScore(VendorProfile v) {
    final rating = (v.rating ?? 0) / 5.0;
    final composite = v.compositeScore / 100.0;
    final reviews = (v.reviewCount / _maxReviews).clamp(0.0, 1.0);
    return rating * 0.50 + composite * 0.35 + reviews * 0.15;
  }

  static double _locationScore(VendorProfile v, double? lat, double? lon) {
    if (lat == null || lon == null || v.latitude == null || v.longitude == null) {
      return 0.5;
    }
    const maxKm = 300.0;
    final dist = _haversineKm(lat, lon, v.latitude!, v.longitude!);
    return (1.0 - dist / maxKm).clamp(0.0, 1.0);
  }

  static double _valueScore(VendorProfile v, BudgetClass bc) {
    final r = (v.rating ?? 0) / 5.0;
    return switch (bc) {
      BudgetClass.highClass =>
        (v.priceTier == VendorPriceTier.high ? 0.70 : 0.0) + r * 0.30,
      BudgetClass.flexible =>
        (r + v.compositeScore / 100.0) / 2.0,
      BudgetClass.budgetFriendly => switch (v.priceTier) {
        VendorPriceTier.low  => 1.00 * 0.55 + r * 0.45,
        VendorPriceTier.mid  => 0.65 * 0.55 + r * 0.45,
        VendorPriceTier.high => 0.0,
      },
    };
  }

  static double _finalScore(double rep, double loc, double val, BudgetClass bc) {
    return switch (bc) {
      BudgetClass.highClass      => rep * 0.55 + val * 0.30 + loc * 0.15,
      BudgetClass.flexible       => rep * 0.40 + val * 0.35 + loc * 0.25,
      BudgetClass.budgetFriendly => val * 0.50 + rep * 0.30 + loc * 0.20,
    };
  }

  // ── AI reasoning text ────────────────────────────────────────────────────────

  static String _reason(VendorProfile v, BudgetClass bc, int rankInCat) {
    final stars = v.rating?.toStringAsFixed(1) ?? '—';
    final rev = v.reviewCount;
    final cat = v.category;
    return switch (bc) {
      BudgetClass.highClass => rankInCat == 1
        ? 'Top luxury pick in $cat — $stars★ from $rev verified clients. The premier choice for an extraordinary wedding.'
        : 'Premium-tier excellence in $cat · $stars★ · Curated for couples who expect only the finest.',
      BudgetClass.flexible => rankInCat == 1
        ? 'Best overall value in $cat · $stars★ from $rev couples. Highest quality-to-price ratio across all tiers.'
        : 'Excellent balanced pick in $cat · $stars★. Strong performance on quality, price, and location.',
      BudgetClass.budgetFriendly => rankInCat == 1
        ? 'Top affordable choice in $cat · $stars★ · $rev satisfied couples. Best quality at the right price.'
        : 'Smart budget pick in $cat · $stars★. Proven reliability — great quality without overspending.',
    };
  }
}

class _ScoredVendor {
  final VendorProfile vendor;
  final double reputation;
  final double location;
  final double value;
  final double finalScore;
  const _ScoredVendor({
    required this.vendor,
    required this.reputation,
    required this.location,
    required this.value,
    required this.finalScore,
  });
}

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

  // ── Budget-tier (free) Photography ─────────────────────────────────────────
  VendorProfile(
    id: 'v-007',
    userId: 'u-007',
    businessName: 'Shutter Joy Photography',
    description: 'Affordable, heartfelt wedding photography. Every love story told beautifully on a budget.',
    category: 'Photography',
    location: 'Nairobi, Kenya',
    latitude: -1.2921,
    longitude: 36.8219,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Candid', 'Natural'],
    rating: 3.9,
    reviewCount: 28,
    compositeScore: 64.0,
    services: [
      VendorService(id: 's-008', vendorId: 'v-007', title: 'Basic Wedding Package',
          description: '6 hours coverage', priceMin: 800, priceMax: 1500, unit: 'package'),
    ],
  ),

  // ── Mid-tier Venue ──────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-008',
    userId: 'u-008',
    businessName: 'Riverside Banquet Hall',
    description: 'Elegant banquet hall with river views — versatile spaces for weddings of all sizes.',
    category: 'Venue',
    location: 'Lagos, Nigeria',
    latitude: 6.5244,
    longitude: 3.3792,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Elegant', 'Modern', 'Indoor'],
    rating: 4.4,
    reviewCount: 56,
    compositeScore: 80.5,
    services: [
      VendorService(id: 's-009', vendorId: 'v-008', title: 'Full Venue Package',
          description: 'Up to 300 guests', priceMin: 3500, priceMax: 7000, unit: 'day'),
    ],
  ),

  // ── Budget-tier Venue ──────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-009',
    userId: 'u-009',
    businessName: 'Community Garden Events',
    description: 'A charming community garden venue — affordable outdoor ceremonies with natural beauty.',
    category: 'Venue',
    location: 'Accra, Ghana',
    latitude: 5.6037,
    longitude: -0.1870,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Outdoor', 'Garden', 'Rustic'],
    rating: 3.7,
    reviewCount: 22,
    compositeScore: 61.0,
    services: [
      VendorService(id: 's-010', vendorId: 'v-009', title: 'Garden Rental',
          description: 'Up to 150 guests', priceMin: 800, priceMax: 2000, unit: 'day'),
    ],
  ),

  // ── Premium Catering ────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-010',
    userId: 'u-010',
    businessName: 'Le Blanc Fine Catering',
    description: 'Michelin-inspired fine dining for weddings — bespoke menus and white-glove service.',
    category: 'Catering',
    location: 'London, UK',
    latitude: 51.5074,
    longitude: -0.1278,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Luxury', 'Fine Dining', 'International'],
    rating: 4.8,
    reviewCount: 72,
    compositeScore: 93.0,
    services: [
      VendorService(id: 's-011', vendorId: 'v-010', title: 'Fine Dining Package',
          description: 'Per person, 4 courses', priceMin: 120, priceMax: 250, unit: 'per person'),
    ],
  ),

  // ── Budget Catering ─────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-011',
    userId: 'u-011',
    businessName: 'Simply Delicious Meals',
    description: 'Wholesome, flavorful wedding meals at prices every couple can afford. No compromise on taste.',
    category: 'Catering',
    location: 'Lusaka, Zambia',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Local Cuisine', 'Buffet'],
    rating: 4.0,
    reviewCount: 31,
    compositeScore: 67.0,
    services: [
      VendorService(id: 's-012', vendorId: 'v-011', title: 'Buffet Package',
          description: 'Per person, 2 courses', priceMin: 25, priceMax: 60, unit: 'per person'),
    ],
  ),

  // ── Mid-tier Floristry ──────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-012',
    userId: 'u-012',
    businessName: 'Green Thumb Florals',
    description: 'Contemporary floral designs using locally sourced blooms — beautiful and responsibly priced.',
    category: 'Floristry',
    location: 'Nairobi, Kenya',
    latitude: -1.2921,
    longitude: 36.8219,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Modern', 'Eco-Friendly', 'Boho'],
    rating: 4.3,
    reviewCount: 38,
    compositeScore: 78.0,
    services: [
      VendorService(id: 's-013', vendorId: 'v-012', title: 'Full Floral Package',
          description: 'Ceremony + reception', priceMin: 1200, priceMax: 3500, unit: 'package'),
    ],
  ),

  // ── Budget Floristry ────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-013',
    userId: 'u-013',
    businessName: 'Bloom on a Budget',
    description: 'Beautiful hand-tied wedding florals at honest prices — for couples who love flowers without the markup.',
    category: 'Floristry',
    location: 'Kampala, Uganda',
    latitude: 0.3476,
    longitude: 32.5825,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Rustic', 'Wildflower', 'Garden'],
    rating: 3.8,
    reviewCount: 19,
    compositeScore: 62.5,
    services: [
      VendorService(id: 's-014', vendorId: 'v-013', title: 'Essential Floral Set',
          description: 'Bridal bouquet + 6 arrangements', priceMin: 400, priceMax: 1200, unit: 'package'),
    ],
  ),

  // ── Premium Cake ────────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-014',
    userId: 'u-014',
    businessName: 'Couture Cake Atelier',
    description: 'Sculptural wedding cakes that double as edible art — haute pâtisserie for luxury weddings.',
    category: 'Cake',
    location: 'New York, NY',
    latitude: 40.7128,
    longitude: -74.0060,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Luxury', 'Artistic', 'Modern'],
    rating: 4.9,
    reviewCount: 45,
    compositeScore: 95.0,
    services: [
      VendorService(id: 's-015', vendorId: 'v-014', title: 'Couture Wedding Cake',
          description: 'Custom sculpted, per serving', priceMin: 12, priceMax: 30, unit: 'per serving'),
    ],
  ),

  // ── Budget Cake ─────────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-015',
    userId: 'u-015',
    businessName: 'Homemade Delights Bakery',
    description: 'Home-baked wedding cakes with love — classic recipes, generous servings, and kind pricing.',
    category: 'Cake',
    location: 'Lagos, Nigeria',
    latitude: 6.5244,
    longitude: 3.3792,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Classic', 'Rustic'],
    rating: 4.1,
    reviewCount: 33,
    compositeScore: 68.5,
    services: [
      VendorService(id: 's-016', vendorId: 'v-015', title: 'Classic Wedding Cake',
          description: 'Per serving', priceMin: 3, priceMax: 8, unit: 'per serving'),
    ],
  ),

  // ── Premium Music ───────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-016',
    userId: 'u-016',
    businessName: 'Grand Symphony Band',
    description: 'Live orchestral performances and premium bands for truly unforgettable wedding receptions.',
    category: 'Music',
    location: 'Dubai, UAE',
    latitude: 25.2048,
    longitude: 55.2708,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Classical', 'Luxury', 'Live Band'],
    rating: 4.8,
    reviewCount: 61,
    compositeScore: 91.5,
    services: [
      VendorService(id: 's-017', vendorId: 'v-016', title: 'Full Evening Package',
          description: 'Live band + DJ hybrid, 6 hrs', priceMin: 4000, priceMax: 8000, unit: 'package'),
    ],
  ),

  // ── Mid-tier Music ──────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-017',
    userId: 'u-017',
    businessName: 'The Groove DJs',
    description: 'Experienced wedding DJs who read the room perfectly — keeping your guests dancing all night.',
    category: 'Music',
    location: 'Johannesburg, South Africa',
    latitude: -26.2041,
    longitude: 28.0473,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['DJ', 'Afrobeats', 'Pop', 'Versatile'],
    rating: 4.5,
    reviewCount: 47,
    compositeScore: 83.0,
    services: [
      VendorService(id: 's-018', vendorId: 'v-017', title: 'Wedding DJ Package',
          description: '5 hours, full sound system', priceMin: 1500, priceMax: 3500, unit: 'package'),
    ],
  ),

  // ── Budget Music ────────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-018',
    userId: 'u-018',
    businessName: 'DJ Splash',
    description: 'Energetic DJ services for weddings on a budget — great music, affordable rates, guaranteed fun.',
    category: 'Music',
    location: 'Lusaka, Zambia',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['DJ', 'Budget', 'High Energy'],
    rating: 3.9,
    reviewCount: 24,
    compositeScore: 63.5,
    services: [
      VendorService(id: 's-019', vendorId: 'v-018', title: 'Basic DJ Package',
          description: '4 hours', priceMin: 400, priceMax: 1000, unit: 'package'),
    ],
  ),

  // ── Premium Videography ─────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-019',
    userId: 'u-019',
    businessName: 'CinemaLove Films',
    description: 'Cinematic wedding films that feel like a Hollywood love story — frame-perfect memories for life.',
    category: 'Videography',
    location: 'New York, NY',
    latitude: 40.7128,
    longitude: -74.0060,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Cinematic', 'Luxury', 'Drone'],
    rating: 4.9,
    reviewCount: 39,
    compositeScore: 94.5,
    services: [
      VendorService(id: 's-020', vendorId: 'v-019', title: 'Feature Film Package',
          description: 'Full day, 4K drone + cinema', priceMin: 4000, priceMax: 7000, unit: 'package'),
    ],
  ),

  // ── Mid-tier Videography ────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-020',
    userId: 'u-020',
    businessName: 'StoryFrame Weddings',
    description: 'Documentary-style wedding films that capture every authentic emotion of your special day.',
    category: 'Videography',
    location: 'Manchester, UK',
    latitude: 53.4808,
    longitude: -2.2426,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Documentary', 'Modern', 'Emotive'],
    rating: 4.6,
    reviewCount: 44,
    compositeScore: 84.0,
    services: [
      VendorService(id: 's-021', vendorId: 'v-020', title: 'Wedding Film Package',
          description: '8 hours, highlight + full edit', priceMin: 1800, priceMax: 3500, unit: 'package'),
    ],
  ),

  // ── Budget Videography ──────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-021',
    userId: 'u-021',
    businessName: 'Moments Captured Films',
    description: 'Affordable wedding videography that preserves your most cherished moments forever.',
    category: 'Videography',
    location: 'Harare, Zimbabwe',
    latitude: -17.8252,
    longitude: 31.0335,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Affordable', 'Candid'],
    rating: 4.0,
    reviewCount: 17,
    compositeScore: 66.0,
    services: [
      VendorService(id: 's-022', vendorId: 'v-021', title: 'Essentials Video Package',
          description: '5 hours, edited highlight reel', priceMin: 600, priceMax: 1500, unit: 'package'),
    ],
  ),

  // ── Premium Transport ────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-022',
    userId: 'u-022',
    businessName: 'Royal Wheels Limousine',
    description: 'White-glove chauffeur services — Rolls-Royce, Bentley & stretch limos for luxury weddings.',
    category: 'Transport',
    location: 'London, UK',
    latitude: 51.5074,
    longitude: -0.1278,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Luxury', 'Limousine', 'Rolls-Royce'],
    rating: 4.7,
    reviewCount: 82,
    compositeScore: 89.0,
    services: [
      VendorService(id: 's-023', vendorId: 'v-022', title: 'Luxury Bridal Fleet',
          description: '3 vehicles, full day', priceMin: 3000, priceMax: 6000, unit: 'package'),
    ],
  ),

  // ── Mid-tier Transport ──────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-023',
    userId: 'u-023',
    businessName: 'Elegance Car Hire',
    description: 'Smart wedding car hire — premium sedans and decorated vehicles at accessible rates.',
    category: 'Transport',
    location: 'Nairobi, Kenya',
    latitude: -1.2921,
    longitude: 36.8219,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Classic', 'Modern Sedan', 'Decorated'],
    rating: 4.4,
    reviewCount: 56,
    compositeScore: 79.5,
    services: [
      VendorService(id: 's-024', vendorId: 'v-023', title: 'Wedding Car Package',
          description: '2 vehicles, half day', priceMin: 1200, priceMax: 2800, unit: 'package'),
    ],
  ),

  // ── Budget Transport ────────────────────────────────────────────────────────
  VendorProfile(
    id: 'v-024',
    userId: 'u-024',
    businessName: 'Classic Rides Zambia',
    description: 'Clean, well-decorated vehicles for wedding transport — reliable service at budget-friendly rates.',
    category: 'Transport',
    location: 'Lusaka, Zambia',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Reliable', 'Decorated'],
    rating: 3.8,
    reviewCount: 29,
    compositeScore: 62.0,
    services: [
      VendorService(id: 's-025', vendorId: 'v-024', title: 'Basic Wedding Ride',
          description: '1 decorated vehicle, 4 hours', priceMin: 300, priceMax: 900, unit: 'package'),
    ],
  ),
];

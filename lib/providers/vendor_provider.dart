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
    final coupleProfile = ref.watch(coupleProfileProvider);
    await Future.delayed(const Duration(milliseconds: 600));

    final filtered = _mockVendors.where((v) => v.category == category).toList();

    final location = coupleProfile?.location;
    if (location == null || location.isEmpty) return filtered;

    final coords = _coordsForLocation(location);
    if (coords == null) return filtered;

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
  if (selectedServices.isEmpty) return _mockVendors.take(4).toList();
  return _mockVendors
      .where((v) => selectedServices.contains(v.category))
      .toList();
});

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

final budgetClassProvider =
    StateProvider<BudgetClass>((ref) => BudgetClass.flexible);

final aiRecommendedVendorsProvider =
    FutureProvider<List<VendorMatch>>((ref) async {
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
    var pool = categories.isEmpty
        ? vendors
        : vendors.where((v) => categories.contains(v.category)).toList();

    pool = pool.where((v) => _eligible(v, budgetClass)).toList();

    final scored = pool.map((v) {
      final rep = _reputationScore(v);
      final loc = _locationScore(v, coupleLat, coupleLon);
      final val = _valueScore(v, budgetClass);
      final fin = _finalScore(rep, loc, val, budgetClass);
      return _ScoredVendor(
          vendor: v, reputation: rep, location: loc, value: val, finalScore: fin);
    }).toList();

    scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));

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
      BudgetClass.flexible => (r + v.compositeScore / 100.0) / 2.0,
      BudgetClass.budgetFriendly => switch (v.priceTier) {
          VendorPriceTier.low => 1.00 * 0.55 + r * 0.45,
          VendorPriceTier.mid => 0.65 * 0.55 + r * 0.45,
          VendorPriceTier.high => 0.0,
        },
    };
  }

  static double _finalScore(double rep, double loc, double val, BudgetClass bc) {
    return switch (bc) {
      BudgetClass.highClass => rep * 0.55 + val * 0.30 + loc * 0.15,
      BudgetClass.flexible => rep * 0.40 + val * 0.35 + loc * 0.25,
      BudgetClass.budgetFriendly => val * 0.50 + rep * 0.30 + loc * 0.20,
    };
  }

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

// ── Vendor ratings ──────────────────────────────────────────────────────────

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

List<double>? _coordsForLocation(String location) {
  final normalized = location.toLowerCase().trim();
  for (final entry in _cityCoordinates.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}

double _matchScore(VendorProfile vendor, double coupleLat, double coupleLon) {
  final reputation = vendor.compositeScore / 100.0;
  if (vendor.latitude == null || vendor.longitude == null) {
    return reputation * 0.5;
  }
  final distKm = _haversineKm(coupleLat, coupleLon, vendor.latitude!, vendor.longitude!);
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

const Map<String, List<double>> _cityCoordinates = {
  // Zambia — primary markets
  'ndola': [-12.9587, 28.6366],
  'kitwe': [-12.8024, 28.2132],
  'lusaka': [-15.4167, 28.2833],
  'livingstone': [-17.8419, 25.8561],
  'kabwe': [-14.4469, 28.4464],
  'kalulushi': [-12.8403, 28.1003],
  'chingola': [-12.5348, 27.8595],
  'mufulira': [-12.5480, 28.2399],
  'solwezi': [-12.1720, 26.3900],
  'chipata': [-13.6456, 32.6475],
  'copperbelt': [-12.9587, 28.6366],
  // Neighbouring countries
  'harare': [-17.8252, 31.0335],
  'nairobi': [-1.2921, 36.8219],
  'johannesburg': [-26.2041, 28.0473],
};

// ── Zambian Mock Vendor Data (ZMW pricing) ──────────────────────────────────

final List<VendorProfile> _mockVendors = [

  // ── VENUE ──────────────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-001',
    userId: 'u-001',
    businessName: 'Mukuba Gardens',
    description:
        'Spacious garden venue seating up to 300 guests, with backup generator, parking for 80 cars and an in-house decor team. Located 10 minutes from Ndola town centre.',
    category: 'Venue',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Garden', 'Outdoor', 'Luxurious'],
    rating: 4.9,
    reviewCount: 42,
    compositeScore: 95.0,
    services: [
      VendorService(
          id: 's-001', vendorId: 'v-001', title: 'Open Air Garden Package',
          description: 'Full venue rental up to 300 guests, includes seating & generator',
          priceMin: 28000, priceMax: 35000, unit: 'event'),
      VendorService(
          id: 's-002', vendorId: 'v-001', title: 'Indoor Hall & Garden Combo',
          description: 'Ceremony garden + indoor reception hall up to 200 guests',
          priceMin: 22000, priceMax: 30000, unit: 'event'),
    ],
  ),

  VendorProfile(
    id: 'v-002',
    userId: 'u-002',
    businessName: 'Twin Palms Events Centre',
    description:
        'Premier events centre in the heart of Kitwe. State-of-the-art facilities for weddings of 50–500 guests. Air-conditioned hall, bridal suite and ample parking.',
    category: 'Venue',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Modern', 'Indoor', 'Air-conditioned'],
    rating: 4.7,
    reviewCount: 63,
    compositeScore: 91.5,
    services: [
      VendorService(
          id: 's-003', vendorId: 'v-002', title: 'Grand Hall Package',
          description: 'Up to 500 guests, full-day rental with bridal suite',
          priceMin: 32000, priceMax: 48000, unit: 'event'),
    ],
  ),

  VendorProfile(
    id: 'v-003',
    userId: 'u-003',
    businessName: 'Riverside Pavilion',
    description:
        'Scenic riverside venue with open-air pavilion and manicured lawns. Perfect for intimate garden weddings of up to 180 guests in Lusaka.',
    category: 'Venue',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Riverside', 'Garden', 'Romantic'],
    rating: 4.5,
    reviewCount: 38,
    compositeScore: 83.0,
    services: [
      VendorService(
          id: 's-004', vendorId: 'v-003', title: 'Garden Ceremony & Pavilion',
          description: 'Up to 180 guests, scenic riverside setting',
          priceMin: 18000, priceMax: 26000, unit: 'event'),
    ],
  ),

  VendorProfile(
    id: 'v-004',
    userId: 'u-004',
    businessName: 'Kalulushi Community Hall',
    description:
        'Affordable, clean and spacious community hall for weddings up to 250 guests. Includes basic seating and a well-stocked kitchen.',
    category: 'Venue',
    location: 'Kalulushi, Copperbelt',
    latitude: -12.8403,
    longitude: 28.1003,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Community', 'Spacious'],
    rating: 3.9,
    reviewCount: 24,
    compositeScore: 64.5,
    services: [
      VendorService(
          id: 's-005', vendorId: 'v-004', title: 'Hall Rental',
          description: 'Up to 250 guests, includes basic seating',
          priceMin: 5000, priceMax: 9000, unit: 'event'),
    ],
  ),

  // ── CATERING ───────────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-005',
    userId: 'u-005',
    businessName: 'Zesco Catering Co.',
    description:
        'Award-winning wedding caterers serving Ndola and the Copperbelt. Specialise in Zambian fusion cuisine with customisable menus and professional service staff.',
    category: 'Catering',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Zambian Cuisine', 'Fusion', 'Professional'],
    rating: 4.8,
    reviewCount: 76,
    compositeScore: 92.0,
    services: [
      VendorService(
          id: 's-006', vendorId: 'v-005', title: 'Full Wedding Catering',
          description: 'Per person — 3-course Zambian fusion meal, full bar service',
          priceMin: 180, priceMax: 280, unit: 'per person'),
    ],
  ),

  VendorProfile(
    id: 'v-006',
    userId: 'u-006',
    businessName: 'Taste of Zambia Catering',
    description:
        'Authentic Zambian cuisine specialists — nshima stations, braai setups, and traditional wedding buffets that delight guests. Based in Lusaka.',
    category: 'Catering',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Traditional', 'Buffet', 'Braai'],
    rating: 4.4,
    reviewCount: 51,
    compositeScore: 80.0,
    services: [
      VendorService(
          id: 's-007', vendorId: 'v-006', title: 'Traditional Wedding Buffet',
          description: 'Per person — nshima + 4 relishes, juice & soft drinks',
          priceMin: 110, priceMax: 180, unit: 'per person'),
    ],
  ),

  VendorProfile(
    id: 'v-007',
    userId: 'u-007',
    businessName: 'Copper Queen Meals',
    description:
        'Budget-friendly catering for weddings on the Copperbelt. Hearty, freshly prepared meals with prompt, friendly service.',
    category: 'Catering',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Local', 'Hearty'],
    rating: 3.8,
    reviewCount: 29,
    compositeScore: 63.0,
    services: [
      VendorService(
          id: 's-008', vendorId: 'v-007', title: 'Budget Wedding Buffet',
          description: 'Per person — 2-course meal, soft drinks',
          priceMin: 70, priceMax: 110, unit: 'per person'),
    ],
  ),

  // ── PHOTOGRAPHY ────────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-008',
    userId: 'u-008',
    businessName: 'Lumino Photography',
    description:
        'Ndola-based award-winning wedding photographer with 8 years of experience. Warm, editorial storytelling for couples who want timeless memories.',
    category: 'Photography',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Editorial', 'Romantic', 'Natural Light'],
    rating: 4.9,
    reviewCount: 54,
    compositeScore: 94.5,
    services: [
      VendorService(
          id: 's-009', vendorId: 'v-008', title: 'Full Day Coverage',
          description: '10 hours, 2 photographers, online gallery',
          priceMin: 9500, priceMax: 13000, unit: 'package'),
      VendorService(
          id: 's-010', vendorId: 'v-008', title: 'Half Day Coverage',
          description: '5 hours, 1 photographer, edited gallery',
          priceMin: 5500, priceMax: 7500, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-009',
    userId: 'u-009',
    businessName: 'Lens & Light Studio',
    description:
        'Modern wedding photography in Kitwe — candid, documentary style that captures real emotion without stiff poses.',
    category: 'Photography',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Candid', 'Documentary', 'Modern'],
    rating: 4.6,
    reviewCount: 37,
    compositeScore: 85.0,
    services: [
      VendorService(
          id: 's-011', vendorId: 'v-009', title: 'Wedding Day Package',
          description: '8 hours, 2 photographers, edited gallery',
          priceMin: 7000, priceMax: 10000, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-010',
    userId: 'u-010',
    businessName: 'Snap & Smile Photography',
    description:
        'Affordable wedding photography in Lusaka. Great eye for detail, honest pricing, fast turnaround on edited photos.',
    category: 'Photography',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Affordable', 'Candid', 'Quick Delivery'],
    rating: 3.9,
    reviewCount: 22,
    compositeScore: 65.5,
    services: [
      VendorService(
          id: 's-012', vendorId: 'v-010', title: 'Essential Wedding Package',
          description: '6 hours, 1 photographer, edited gallery',
          priceMin: 3500, priceMax: 5000, unit: 'package'),
    ],
  ),

  // ── DECOR & FLOWERS ────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-011',
    userId: 'u-011',
    businessName: 'Lumwana Decor & Blooms',
    description:
        'Zambia\'s premier wedding decor and floral design studio. Full-service setup: arches, centrepieces, fresh flowers, draping and lighting across all budgets.',
    category: 'Decor & flowers',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Luxury', 'Fresh Flowers', 'Full Setup'],
    rating: 4.8,
    reviewCount: 61,
    compositeScore: 91.0,
    services: [
      VendorService(
          id: 's-013', vendorId: 'v-011', title: 'Premium Decor Package',
          description: 'Full venue setup — arch, flowers, draping, centrepieces, lighting',
          priceMin: 12000, priceMax: 20000, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-012',
    userId: 'u-012',
    businessName: 'Copper Petal Florals',
    description:
        'Beautiful wedding florals and table decor for Kitwe and surrounding areas. Fresh, seasonal blooms sourced from local growers.',
    category: 'Decor & flowers',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Fresh Blooms', 'Rustic', 'Eco-friendly'],
    rating: 4.4,
    reviewCount: 33,
    compositeScore: 79.5,
    services: [
      VendorService(
          id: 's-014', vendorId: 'v-012', title: 'Florals & Centrepieces',
          description: 'Bridal bouquet + 10 table arrangements + ceremony arch',
          priceMin: 5500, priceMax: 9500, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-013',
    userId: 'u-013',
    businessName: 'Bloom House Zambia',
    description:
        'Affordable decor and florals for budget-conscious couples. Simple, elegant designs that make any venue look beautiful.',
    category: 'Decor & flowers',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Simple', 'Elegant'],
    rating: 3.8,
    reviewCount: 18,
    compositeScore: 62.0,
    services: [
      VendorService(
          id: 's-015', vendorId: 'v-013', title: 'Basic Floral Package',
          description: 'Bridal bouquet + 5 table arrangements',
          priceMin: 2000, priceMax: 3500, unit: 'package'),
    ],
  ),

  // ── DJ & MC ────────────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-014',
    userId: 'u-014',
    businessName: 'Zambezi Sounds DJ',
    description:
        'Ndola\'s most-booked wedding DJ. Afrobeats, R&B, rumba and international hits. Full sound system, MC services and LED lighting included.',
    category: 'DJ & MC',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Afrobeats', 'R&B', 'MC', 'LED Lighting'],
    rating: 4.9,
    reviewCount: 88,
    compositeScore: 93.5,
    services: [
      VendorService(
          id: 's-016', vendorId: 'v-014', title: 'Full Wedding Night Package',
          description: 'DJ + MC + full sound system + LED lighting, 6 hours',
          priceMin: 6500, priceMax: 9000, unit: 'event'),
    ],
  ),

  VendorProfile(
    id: 'v-015',
    userId: 'u-015',
    businessName: 'DJ Chisomo',
    description:
        'Versatile wedding DJ based in Lusaka. Specialises in seamless crowd reading — from ceremony to last dance. PA system hire included.',
    category: 'DJ & MC',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Versatile', 'Crowd Reader', 'PA System'],
    rating: 4.5,
    reviewCount: 47,
    compositeScore: 83.0,
    services: [
      VendorService(
          id: 's-017', vendorId: 'v-015', title: 'Wedding DJ Package',
          description: 'DJ + PA system, 5 hours',
          priceMin: 3500, priceMax: 5500, unit: 'event'),
    ],
  ),

  VendorProfile(
    id: 'v-016',
    userId: 'u-016',
    businessName: 'Copperbelt DJ Services',
    description:
        'Budget-friendly DJ hire for weddings across the Copperbelt. Good music selection, reliable equipment, punctual setup.',
    category: 'DJ & MC',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Reliable', 'Punctual'],
    rating: 3.9,
    reviewCount: 26,
    compositeScore: 64.0,
    services: [
      VendorService(
          id: 's-018', vendorId: 'v-016', title: 'Basic DJ Package',
          description: 'DJ + basic sound system, 4 hours',
          priceMin: 1500, priceMax: 2800, unit: 'event'),
    ],
  ),

  // ── TRANSPORT ──────────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-017',
    userId: 'u-017',
    businessName: 'Bemba Bridal Cars',
    description:
        'Luxury bridal car hire across the Copperbelt. Classic decorated vehicles, chauffeur-driven, including Benz and Lexus models. On-time, elegant service.',
    category: 'Transport',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Luxury', 'Chauffeur', 'Decorated'],
    rating: 4.7,
    reviewCount: 44,
    compositeScore: 89.0,
    services: [
      VendorService(
          id: 's-019', vendorId: 'v-017', title: 'Bridal Fleet Package',
          description: '3 luxury vehicles, full day, chauffeur-driven',
          priceMin: 4500, priceMax: 7000, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-018',
    userId: 'u-018',
    businessName: 'Twin Palms Transport',
    description:
        'Wedding transport specialists in Kitwe. Clean, well-maintained decorated vehicles for bridal parties and guests. Competitive pricing.',
    category: 'Transport',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Decorated', 'Reliable', 'Fleet'],
    rating: 4.3,
    reviewCount: 31,
    compositeScore: 77.5,
    services: [
      VendorService(
          id: 's-020', vendorId: 'v-018', title: 'Wedding Car Package',
          description: '2 vehicles, half day, decorated',
          priceMin: 2000, priceMax: 3500, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-019',
    userId: 'u-019',
    businessName: 'Classic Rides Zambia',
    description:
        'Affordable wedding vehicle hire in Lusaka and surrounding areas. Decorated saloons and mini-buses for bridal party and guest transport.',
    category: 'Transport',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Mini-bus', 'Decorated'],
    rating: 3.7,
    reviewCount: 19,
    compositeScore: 61.0,
    services: [
      VendorService(
          id: 's-021', vendorId: 'v-019', title: 'Basic Wedding Ride',
          description: '1 decorated vehicle, 4 hours',
          priceMin: 800, priceMax: 1500, unit: 'package'),
    ],
  ),

  // ── WEDDING ATTIRE ─────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-020',
    userId: 'u-020',
    businessName: 'Lusaka Bridal House',
    description:
        'Zambia\'s most celebrated bridal boutique. Bespoke gowns, suits and traditional attire for the full wedding party. Custom tailoring with 4-week turnaround.',
    category: 'Wedding attire',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Bespoke', 'Traditional', 'Full Party'],
    rating: 4.8,
    reviewCount: 67,
    compositeScore: 90.5,
    services: [
      VendorService(
          id: 's-022', vendorId: 'v-020', title: 'Bridal Gown (Bespoke)',
          description: 'Full custom design, 3 fittings included',
          priceMin: 6000, priceMax: 14000, unit: 'gown'),
      VendorService(
          id: 's-023', vendorId: 'v-020', title: 'Groom Suit (Bespoke)',
          description: 'Custom-tailored suit with 2 fittings',
          priceMin: 3500, priceMax: 7000, unit: 'suit'),
    ],
  ),

  VendorProfile(
    id: 'v-021',
    userId: 'u-021',
    businessName: 'Bemba Bridal Wear',
    description:
        'Ndola-based bridal wear specialist combining modern style with Zambian cultural dress. Gowns, chitenge-inspired attire, groom suits and bridesmaid dresses.',
    category: 'Wedding attire',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Chitenge', 'Modern', 'Cultural'],
    rating: 4.5,
    reviewCount: 41,
    compositeScore: 83.5,
    services: [
      VendorService(
          id: 's-024', vendorId: 'v-021', title: 'Bridal Gown',
          description: 'Semi-custom gown with 2 fittings',
          priceMin: 3800, priceMax: 7500, unit: 'gown'),
    ],
  ),

  // ── CAKE & SWEETS ──────────────────────────────────────────────────────────

  VendorProfile(
    id: 'v-022',
    userId: 'u-022',
    businessName: 'Sweet Dreams Bakery',
    description:
        'Ndola\'s premium wedding cake studio. Multi-tiered custom cakes, cupcake towers, and dessert tables for weddings of all sizes. Tasting sessions available.',
    category: 'Cake & sweets',
    location: 'Ndola, Copperbelt',
    latitude: -12.9587,
    longitude: 28.6366,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Tiered Cakes', 'Custom', 'Dessert Table'],
    rating: 4.9,
    reviewCount: 58,
    compositeScore: 92.0,
    services: [
      VendorService(
          id: 's-025', vendorId: 'v-022', title: 'Custom Wedding Cake',
          description: 'Multi-tier, custom design, per serving',
          priceMin: 45, priceMax: 90, unit: 'per serving'),
      VendorService(
          id: 's-026', vendorId: 'v-022', title: 'Dessert Table Package',
          description: 'Mini cakes, cupcakes & sweets for 100 guests',
          priceMin: 6500, priceMax: 9500, unit: 'package'),
    ],
  ),

  VendorProfile(
    id: 'v-023',
    userId: 'u-023',
    businessName: 'Copperbelt Cakes & Co.',
    description:
        'Kitwe\'s go-to wedding cake bakers. Moist, beautifully decorated cakes using local ingredients. Traditional and modern designs at fair prices.',
    category: 'Cake & sweets',
    location: 'Kitwe, Copperbelt',
    latitude: -12.8024,
    longitude: 28.2132,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Traditional', 'Modern', 'Local Ingredients'],
    rating: 4.4,
    reviewCount: 36,
    compositeScore: 79.0,
    services: [
      VendorService(
          id: 's-027', vendorId: 'v-023', title: 'Wedding Cake',
          description: '3-tier custom cake, per serving',
          priceMin: 30, priceMax: 60, unit: 'per serving'),
    ],
  ),

  VendorProfile(
    id: 'v-024',
    userId: 'u-024',
    businessName: 'Lusaka Home Bakes',
    description:
        'Home-based bakery in Lusaka producing delicious, affordable wedding cakes. Traditional recipes with modern presentation.',
    category: 'Cake & sweets',
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Budget', 'Home-baked', 'Traditional'],
    rating: 4.0,
    reviewCount: 27,
    compositeScore: 67.5,
    services: [
      VendorService(
          id: 's-028', vendorId: 'v-024', title: 'Classic Wedding Cake',
          description: 'Classic 2-tier cake, per serving',
          priceMin: 18, priceMax: 35, unit: 'per serving'),
    ],
  ),
];

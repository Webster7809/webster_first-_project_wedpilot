import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../core/services/wedding_ai_service.dart';
import '../core/utils/geo_utils.dart';
import 'auth_provider.dart';
import 'vendor_provider.dart';

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

/// Location entered by the couple in wizard Step 0 — takes priority over profile location.
final wizardLocationProvider = StateProvider<String?>((ref) => null);

/// Style preferences chosen by the couple in wizard Step 2 — feeds the AI vendor matcher.
final wizardStylesProvider = StateProvider<List<String>>((ref) => const []);

final aiRecommendedVendorsProvider =
    FutureProvider<List<VendorMatch>>((ref) async {
  final budgetClass = ref.watch(budgetClassProvider);
  final categories = ref.watch(selectedServiceCategoriesProvider);
  final coupleProfile = ref.watch(coupleProfileProvider);
  final wizardLocation = ref.watch(wizardLocationProvider);
  final wizardStyles = ref.watch(wizardStylesProvider);

  final locationString = (wizardLocation != null && wizardLocation.isNotEmpty)
      ? wizardLocation
      : coupleProfile?.location;
  final coords =
      locationString != null ? coordsForLocation(locationString) : null;

  final allVendors = await ref.watch(allVendorsProvider.future);
  final pool = _AiEngine.filterEligible(allVendors, budgetClass, categories);
  final scored = _AiEngine.scoreAll(pool, budgetClass, coords?[0], coords?[1]);
  final localFallback =
      _AiEngine.recommend(pool: pool, scored: scored, budgetClass: budgetClass);

  if (scored.isEmpty) return localFallback;

  try {
    final suggestions = await WeddingAiService.instance.matchVendors(
      budgetClass: budgetClass.name,
      location: locationString,
      styles: wizardStyles,
      categorized: _AiEngine.buildCandidates(scored),
    );

    final requestedCategories = scored.map((s) => s.vendor.category).toSet();
    final valid = requestedCategories.every((cat) {
      final sug = suggestions[cat];
      return sug != null &&
          scored.any((s) => s.vendor.category == cat && s.vendor.id == sug.vendorId);
    });
    if (!valid) return localFallback;

    final catCounts = <String, int>{
      for (final cat in requestedCategories)
        cat: scored.where((s) => s.vendor.category == cat).length,
    };

    final results = <VendorMatch>[];
    for (final entry in suggestions.entries) {
      final match = scored.firstWhere((s) => s.vendor.id == entry.value.vendorId);
      results.add(VendorMatch(
        vendorId: match.vendor.id,
        vendor: match.vendor,
        finalScore: entry.value.confidence,
        reputationScore: match.reputation,
        budgetScore: match.value,
        locationScore: match.location,
        availabilityScore: 1.0,
        reasoning: entry.value.reasoning,
        rankInCategory: 1,
        totalInCategory: catCounts[entry.key] ?? 1,
      ));
    }
    return results;
  } catch (_) {
    return localFallback;
  }
});

// ── AI Recommendation Engine ────────────────────────────────────────────────
//
// `filterEligible` + `scoreAll` compute the grounding signals sent to the real
// LLM matcher (see `WeddingAiService.matchVendors`). `recommend` composes them
// into a fully ranked local result and serves as the offline fallback when the
// LLM call fails or returns something malformed.

class _AiEngine {
  _AiEngine._();

  static const double _minRatingHighClass = 4.5;
  static const double _minRatingBudget = 3.5;
  static const double _minRatingFlexible = 3.0;

  static List<VendorProfile> filterEligible(
    List<VendorProfile> vendors,
    BudgetClass budgetClass,
    List<String> categories,
  ) {
    var pool = categories.isEmpty
        ? vendors
        : vendors.where((v) => categories.contains(v.category)).toList();

    pool = pool.where((v) => _eligible(v, budgetClass)).toList();
    return pool;
  }

  static List<_ScoredVendor> scoreAll(
    List<VendorProfile> pool,
    BudgetClass budgetClass,
    double? coupleLat,
    double? coupleLon,
  ) {
    return pool.map((v) {
      final rep = v.performanceScore;
      final loc = _locationScore(v, coupleLat, coupleLon);
      final val = _valueScore(v, budgetClass);
      final fin = _finalScore(rep, loc, val, budgetClass);
      return _ScoredVendor(
          vendor: v, reputation: rep, location: loc, value: val, finalScore: fin);
    }).toList();
  }

  /// Groups scored vendors by category into request DTOs for the AI matcher.
  static Map<String, List<VendorMatchCandidate>> buildCandidates(
    List<_ScoredVendor> scored,
  ) {
    final byCategory = <String, List<VendorMatchCandidate>>{};
    for (final s in scored) {
      final v = s.vendor;
      byCategory.putIfAbsent(v.category, () => []).add(
            VendorMatchCandidate(
              vendorId: v.id,
              businessName: v.businessName,
              location: v.location,
              styleTags: v.styleTags,
              rating: v.rating,
              reviewCount: v.reviewCount,
              priceTier: v.priceTier.name,
              priceMin: v.priceMin,
              priceMax: v.priceMax,
              reputationScore: s.reputation,
              locationScore: s.location,
              valueScore: s.value,
            ),
          );
    }
    return byCategory;
  }

  /// Local, deterministic ranking — cannot throw. Used as the LLM fallback.
  static List<VendorMatch> recommend({
    required List<VendorProfile> pool,
    required List<_ScoredVendor> scored,
    required BudgetClass budgetClass,
  }) {
    final ranked = [...scored]..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    final catTotal = <String, int>{};
    for (final s in ranked) {
      catTotal[s.vendor.category] = (catTotal[s.vendor.category] ?? 0) + 1;
    }
    final catRank = <String, int>{};

    return ranked.map((s) {
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

  static double _locationScore(VendorProfile v, double? lat, double? lon) {
    if (lat == null || lon == null || v.latitude == null || v.longitude == null) {
      return 0.5;
    }
    const maxKm = 300.0;
    final dist = haversineKm(lat, lon, v.latitude!, v.longitude!);
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

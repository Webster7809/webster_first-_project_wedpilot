import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../core/constants/app_constants.dart';
import '../core/services/couple_profile_service.dart';
import '../core/services/wedding_ai_service.dart';
import '../core/utils/geo_utils.dart';
import 'auth_provider.dart';
import 'budget_provider.dart';
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
  final weddingDateStr = coupleProfile?.weddingDate != null
      ? coupleProfile!.weddingDate!.toIso8601String().split('T').first
      : null;

  final allVendors = await ref.watch(allVendorsProvider.future);
  final pool = _AiEngine.filterEligible(allVendors, budgetClass, categories);

  // The couple's allocated spend per category. Prefers their actual saved
  // Budget (which reflects any manual reallocation they've done) when it's
  // loaded; the Budget is created via an async call fired at the same time
  // as this provider, so it may still be null/stale here — in that case,
  // fall back to splitting their entered total budget via the same default
  // percentages used elsewhere in the app (see AppConstants).
  final savedBudget = ref.watch(budgetProvider).data;
  final realAllocations = <String, double>{
    if (savedBudget != null)
      for (final c in savedBudget.categories) c.categoryName: c.allocatedAmount,
  };
  final totalBudget = coupleProfile?.totalBudget;
  final categoryBudgets = <String, double>{
    for (final cat in pool.map((v) => v.category).toSet())
      if (realAllocations[cat] != null)
        cat: realAllocations[cat]!
      else if (totalBudget != null &&
          totalBudget > 0 &&
          AppConstants.defaultBudgetAllocation[cat] != null)
        cat: totalBudget * AppConstants.defaultBudgetAllocation[cat]!,
  };

  final scored = _AiEngine.scoreAll(
      pool, budgetClass, coords?[0], coords?[1], weddingDateStr, categoryBudgets);
  final localFallback = _AiEngine.recommend(
      pool: pool, scored: scored, budgetClass: budgetClass, styles: wizardStyles);

  final List<VendorMatch> matches;
  if (scored.isEmpty) {
    matches = localFallback;
  } else {
    matches = await _matchWithAi(scored, localFallback, budgetClass, locationString, wizardStyles, categoryBudgets);
  }

  await _syncTopMatches(ref, matches);
  return matches;
});

Future<List<VendorMatch>> _matchWithAi(
  List<_ScoredVendor> scored,
  List<VendorMatch> localFallback,
  BudgetClass budgetClass,
  String? locationString,
  List<String> wizardStyles,
  Map<String, double> categoryBudgets,
) async {
  try {
    final suggestions = await WeddingAiService.instance.matchVendors(
      budgetClass: budgetClass.name,
      location: locationString,
      styles: wizardStyles,
      categorized: _AiEngine.buildCandidates(scored),
      categoryBudgets: categoryBudgets,
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
        reasoningSteps: entry.value.reasoningSteps,
        rankInCategory: 1,
        totalInCategory: catCounts[entry.key] ?? 1,
      ));
    }
    return results;
  } catch (_) {
    return localFallback;
  }
}

/// Reports the current top pick per category to the backend, which persists
/// it and notifies the couple only when a pick is new or has changed since
/// last time — this never fires on its own, only relaying a real computation.
Future<void> _syncTopMatches(Ref ref, List<VendorMatch> matches) async {
  final token = ref.read(authProvider.notifier).accessToken;
  if (token == null) return;
  final topPicks = matches.where((m) => m.rankInCategory == 1).toList();
  if (topPicks.isEmpty) return;
  try {
    await CoupleProfileService.instance.syncVendorMatches(
      token,
      topPicks
          .map((m) => {
                'category': m.vendor.category,
                'vendor_id': m.vendorId,
                'confidence': m.finalScore,
              })
          .toList(),
    );
  } catch (_) {
    // Best-effort — a failed sync shouldn't block showing the couple their matches.
  }
}

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
    String? weddingDateStr,
    Map<String, double> categoryBudgets,
  ) {
    return pool.map((v) {
      final rep = v.performanceScore;
      final loc = _locationScore(v, coupleLat, coupleLon);
      final val = _valueScore(v, budgetClass);
      final isBooked =
          weddingDateStr != null && v.blockedDates.contains(weddingDateStr);
      final categoryBudget = categoryBudgets[v.category];
      final overBudgetRatio = categoryBudget != null && categoryBudget > 0
          ? ((v.priceMin - categoryBudget) / categoryBudget).clamp(0.0, 1.0)
          : 0.0;
      final fin =
          _finalScore(rep, loc, val, budgetClass, isBooked, overBudgetRatio);
      return _ScoredVendor(
        vendor: v,
        reputation: rep,
        location: loc,
        value: val,
        finalScore: fin,
        isBookedOnWeddingDate: isBooked,
        categoryBudget: categoryBudget,
        overBudgetRatio: overBudgetRatio,
      );
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
              isBookedOnWeddingDate: s.isBookedOnWeddingDate,
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
    List<String> styles = const [],
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
      final steps = _reasonSteps(s.vendor, budgetClass, rank, s.isBookedOnWeddingDate,
          s.categoryBudget, s.overBudgetRatio, styles);
      return VendorMatch(
        vendorId: s.vendor.id,
        vendor: s.vendor,
        finalScore: s.finalScore,
        reputationScore: s.reputation,
        budgetScore: s.value,
        locationScore: s.location,
        availabilityScore: s.isBookedOnWeddingDate ? 0.0 : 1.0,
        reasoning: steps.map((r) => '${r.label}: ${r.text}').join(' '),
        reasoningSteps: steps,
        rankInCategory: rank,
        totalInCategory: catTotal[s.vendor.category]!,
      );
    }).toList();
  }

  static bool _eligible(VendorProfile v, BudgetClass bc) {
    // Brand-new vendors have no reviews yet, so they haven't had a chance to
    // earn a rating — exempt them from the rating floor so they're still
    // visible to the AI matcher instead of being silently excluded forever.
    if (v.reviewCount == 0) {
      return switch (bc) {
        BudgetClass.highClass => v.priceTier == VendorPriceTier.high,
        BudgetClass.flexible => true,
        BudgetClass.budgetFriendly => v.priceTier != VendorPriceTier.high,
      };
    }
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

  // Booked vendors aren't excluded outright, but a confirmed conflict on the
  // couple's date should outweigh most quality/price differences, so they're
  // pushed toward the bottom of their category rather than removed.
  static const double _bookedPenalty = 0.45;

  // Being priced beyond the couple's allocated budget for a category is a
  // graduated penalty (worse the further over they are), not a hard cutoff —
  // an over-budget vendor can still surface as the pick if nothing in that
  // category fits, but it will rank below anything that does fit.
  static const double _overBudgetWeight = 0.40;

  static double _finalScore(double rep, double loc, double val,
      BudgetClass bc, bool isBooked, double overBudgetRatio) {
    final base = switch (bc) {
      BudgetClass.highClass => rep * 0.55 + val * 0.30 + loc * 0.15,
      BudgetClass.flexible => rep * 0.40 + val * 0.35 + loc * 0.25,
      BudgetClass.budgetFriendly => val * 0.50 + rep * 0.30 + loc * 0.20,
    };
    final penalized = isBooked ? base - _bookedPenalty : base;
    return penalized - overBudgetRatio * _overBudgetWeight;
  }

  /// Mirrors the 4 named steps the real AI matcher is prompted to return
  /// (see the /api/vendor-match prompt), so the offline fallback reads the
  /// same way as a live AI pick instead of one run-on sentence.
  static List<ReasoningStep> _reasonSteps(
    VendorProfile v,
    BudgetClass bc,
    int rankInCat,
    bool isBooked,
    double? categoryBudget,
    double overBudgetRatio,
    List<String> styles,
  ) {
    final stars = v.rating?.toStringAsFixed(1) ?? '—';
    final rev = v.reviewCount;
    final cat = v.category;

    final String budgetText;
    if (categoryBudget == null) {
      budgetText = 'No budget entered for $cat yet, so price wasn\'t used as a filter here.';
    } else if (overBudgetRatio <= 0) {
      budgetText = 'Fits within your ~${categoryBudget.toStringAsFixed(0)} allocation for $cat.';
    } else {
      budgetText =
          'Starts around ${v.priceMin.toStringAsFixed(0)}, above your ~${categoryBudget.toStringAsFixed(0)} '
          'budget for $cat — still the closest available fit. You can move forward by asking for a '
          'smaller/custom package, trimming scope for $cat, or shifting budget from a lower-priority category.';
    }

    final availabilityText = isBooked
        ? 'Already booked on your wedding date — confirm availability before relying on them, or line up a backup in $cat.'
        : 'Open on your wedding date, based on their calendar.';

    final overlap = styles
        .where((pref) => v.styleTags.any((tag) => tag.toLowerCase() == pref.toLowerCase()))
        .toList();
    final styleText = overlap.isNotEmpty
        ? 'Matches your ${overlap.join(', ')} style preference${overlap.length > 1 ? 's' : ''}.'
        : v.styleTags.isNotEmpty
            ? 'Known for ${v.styleTags.take(2).join(', ')} — no direct overlap with your stated style, but still strong in $cat.'
            : 'No style tags on file to compare against your preferences.';

    final String verdictText;
    if (isBooked) {
      verdictText =
          'Ranked #$rankInCat in $cat on quality, but the date conflict makes this a backup unless they confirm availability.';
    } else if (categoryBudget != null && overBudgetRatio > 0) {
      verdictText = 'Best available pick in $cat given the budget gap — worth the package conversation above.';
    } else {
      verdictText = switch (bc) {
        BudgetClass.highClass => rankInCat == 1
            ? 'Top luxury pick in $cat — $stars★ from $rev verified clients, the premier choice for an extraordinary wedding.'
            : 'Premium-tier excellence in $cat · $stars★, curated for couples who expect only the finest.',
        BudgetClass.flexible => rankInCat == 1
            ? 'Best overall value in $cat · $stars★ from $rev couples — the highest quality-to-price ratio across all tiers.'
            : 'Excellent balanced pick in $cat · $stars★, strong on quality, price, and location.',
        BudgetClass.budgetFriendly => rankInCat == 1
            ? 'Top affordable choice in $cat · $stars★ · $rev satisfied couples — best quality at the right price.'
            : 'Smart budget pick in $cat · $stars★, proven reliability without overspending.',
      };
    }

    return [
      ReasoningStep(label: ReasoningStep.budgetFit, text: budgetText),
      ReasoningStep(label: ReasoningStep.availability, text: availabilityText),
      ReasoningStep(label: ReasoningStep.styleMatch, text: styleText),
      ReasoningStep(label: ReasoningStep.verdict, text: verdictText),
    ];
  }
}

class _ScoredVendor {
  final VendorProfile vendor;
  final double reputation;
  final double location;
  final double value;
  final double finalScore;
  final bool isBookedOnWeddingDate;
  final double? categoryBudget;
  final double overBudgetRatio;
  const _ScoredVendor({
    required this.vendor,
    required this.reputation,
    required this.location,
    required this.value,
    required this.finalScore,
    this.isBookedOnWeddingDate = false,
    this.categoryBudget,
    this.overBudgetRatio = 0.0,
  });
}

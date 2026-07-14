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

/// Thrown by [aiRecommendedVendorsProvider] when the couple hasn't entered a
/// wedding budget yet. The AI must never pick or rank a vendor without a real
/// budget to weigh price against — surfacing this as a distinct error (rather
/// than silently matching on price-blind scores) lets the UI ask the couple
/// to enter their budget instead of showing recommendations that were never
/// actually checked against what they intend to spend.
class NoBudgetSetException implements Exception {
  const NoBudgetSetException();
}

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
  final savedBudget = ref.watch(budgetProvider).data;

  // A budget the couple actually entered is the one grounding fact every
  // price-based score and every "budget fit" reasoning line depends on.
  // Without it there's nothing real to weigh a vendor's price against, so
  // rather than silently matching on price-blind scores, refuse to pick or
  // rank anyone until the couple sets a real amount.
  final enteredBudget = savedBudget?.totalAmount ?? coupleProfile?.totalBudget;
  if (enteredBudget == null || enteredBudget <= 0) {
    throw const NoBudgetSetException();
  }

  final locationString = (wizardLocation != null && wizardLocation.isNotEmpty)
      ? wizardLocation
      : coupleProfile?.location;
  final coords =
      locationString != null ? coordsForLocation(locationString) : null;
  final weddingDateStr = coupleProfile?.weddingDate != null
      ? coupleProfile!.weddingDate!.toIso8601String().split('T').first
      : null;

  final allVendors = await ref.watch(allVendorsProvider.future);
  final eligible = _AiEngine.filterEligible(allVendors, categories);
  final pool = eligible.pool;

  // The couple's allocated spend per category. Prefers their actual saved
  // Budget (which reflects any manual reallocation they've done) when it's
  // loaded; the Budget is created via an async call fired at the same time
  // as this provider, so it may still be null/stale here — in that case,
  // fall back to splitting their entered total budget via the same default
  // percentages used elsewhere in the app (see AppConstants).
  final realAllocations = <String, double>{
    if (savedBudget != null)
      for (final c in savedBudget.categories) c.categoryName: c.allocatedAmount,
  };
  final categoryBudgets = <String, double>{
    for (final cat in pool.map((v) => v.category).toSet())
      if (realAllocations[cat] != null)
        cat: realAllocations[cat]!
      else if (AppConstants.defaultBudgetAllocation[cat] != null)
        cat: enteredBudget * AppConstants.defaultBudgetAllocation[cat]!,
  };

  final scored = _AiEngine.scoreAll(pool, budgetClass, coords?[0], coords?[1],
      weddingDateStr, categoryBudgets, eligible.tiers);
  final localFallback = _AiEngine.recommend(
      pool: pool,
      scored: scored,
      budgetClass: budgetClass,
      styles: wizardStyles);

  final List<VendorMatch> matches;
  if (scored.isEmpty) {
    matches = localFallback;
  } else {
    matches = await _matchWithAi(scored, localFallback, budgetClass,
        locationString, wizardStyles, categoryBudgets);
  }

  final alternates = _AiEngine.budgetAlternates(scored, matches, categoryBudgets);
  final combined = [...matches, ...alternates];

  await _syncTopMatches(ref, combined);
  return combined;
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
        fitsBudget: entry.value.fitsBudget,
        budgetDeltaPercent: entry.value.budgetDeltaPercent,
        selectionBasis: entry.value.selectionBasis,
        noteToCouple: entry.value.noteToCouple,
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

  /// Every vendor in a requested category is always included in the pool —
  /// wedding class and star rating shape *ranking* (see [scoreAll] and
  /// [_valueScore]), they never zero out a category outright. A hard
  /// price-tier/rating gate here used to mean a whole category could come
  /// back with nothing the moment no vendor cleared its bar (e.g. "High
  /// class" required both the top price tier *and* a 4.5+ rating) — even
  /// when the category had plenty of real vendors the couple could see and
  /// afford. Ranking already degrades gracefully to the "closest available
  /// fit" (see the budget-fit reasoning text below); it just needs a
  /// non-empty pool to work with.
  static ({List<VendorProfile> pool, Map<String, VendorPriceTier> tiers}) filterEligible(
    List<VendorProfile> vendors,
    List<String> categories,
  ) {
    final pool = categories.isEmpty
        ? vendors
        : vendors.where((v) => categories.contains(v.category)).toList();
    final tiers = _relativePriceTiers(pool);
    return (pool: pool, tiers: tiers);
  }

  /// Buckets each vendor into low/mid/high relative to other vendors in the
  /// *same category* who have actually entered pricing — a photographer and
  /// a venue are priced on completely different scales, so "premium" only
  /// means anything when compared within the same service type. Vendors
  /// without priced services yet (nothing to compare) fall back to their
  /// subscription tier as the best available signal.
  static Map<String, VendorPriceTier> _relativePriceTiers(
    List<VendorProfile> vendors,
  ) {
    final byCategory = <String, List<VendorProfile>>{};
    for (final v in vendors) {
      byCategory.putIfAbsent(v.category, () => []).add(v);
    }

    final tiers = <String, VendorPriceTier>{};
    for (final group in byCategory.values) {
      final priced = group.where((v) => v.priceMax > 0).toList()
        ..sort((a, b) => (a.priceMin + a.priceMax).compareTo(b.priceMin + b.priceMax));

      for (var i = 0; i < priced.length; i++) {
        if (priced.length == 1) {
          tiers[priced[i].id] = VendorPriceTier.mid;
          continue;
        }
        final position = i / (priced.length - 1);
        tiers[priced[i].id] = position < 1 / 3
            ? VendorPriceTier.low
            : position < 2 / 3
                ? VendorPriceTier.mid
                : VendorPriceTier.high;
      }

      for (final v in group) {
        tiers.putIfAbsent(v.id, () => v.priceTier);
      }
    }
    return tiers;
  }

  static List<_ScoredVendor> scoreAll(
    List<VendorProfile> pool,
    BudgetClass budgetClass,
    double? coupleLat,
    double? coupleLon,
    String? weddingDateStr,
    Map<String, double> categoryBudgets,
    Map<String, VendorPriceTier> priceTiers,
  ) {
    return pool.map((v) {
      final tier = priceTiers[v.id] ?? v.priceTier;
      final rep = v.performanceScore;
      final loc = _locationScore(v, coupleLat, coupleLon);
      final categoryBudget = categoryBudgets[v.category];
      final val = _valueScore(v, budgetClass, categoryBudget);
      final isBooked =
          weddingDateStr != null && v.blockedDates.contains(weddingDateStr);
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
        priceTier: tier,
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
              feedbackCount: v.feedbackCount,
              priceTier: s.priceTier.name,
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
          s.categoryBudget, s.overBudgetRatio, styles, s.location);

      // Mirrors the backend's budget-fit/fallback rules (see /api/vendor-match):
      // a category with no allocated budget, or a pick priced at or under it,
      // counts as an exact match; eligibility filtering has already restricted
      // this class's pool to its matching price tier, so anything left over
      // budget is by construction the class's best remaining tier fit.
      final fitsBudget = s.categoryBudget == null || s.overBudgetRatio <= 0;
      final budgetDeltaPercent = (!fitsBudget && s.categoryBudget != null && s.categoryBudget! > 0)
          ? (((s.vendor.priceMin - s.categoryBudget!) / s.categoryBudget!) * 100).round().toDouble()
          : null;
      final noteToCouple = fitsBudget
          ? 'Fits your allocated budget for ${s.vendor.category}.'
          : 'No ${budgetClass.displayName.toLowerCase()} pick fit your budget for ${s.vendor.category} '
              'exactly, so this is the closest match for that tier'
              '${budgetDeltaPercent != null ? ' — about ${budgetDeltaPercent.toStringAsFixed(0)}% over your allocation' : ''}.';

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
        fitsBudget: fitsBudget,
        budgetDeltaPercent: budgetDeltaPercent,
        selectionBasis:
            fitsBudget ? SelectionBasis.exactBudgetMatch : SelectionBasis.weddingClassBestFit,
        noteToCouple: noteToCouple,
      );
    }).toList();
  }

  static double _locationScore(VendorProfile v, double? lat, double? lon) {
    if (lat == null || lon == null || v.latitude == null || v.longitude == null) {
      return 0.5;
    }
    const maxKm = 300.0;
    final dist = haversineKm(lat, lon, v.latitude!, v.longitude!);
    return (1.0 - dist / maxKm).clamp(0.0, 1.0);
  }

  /// Price fit, scaled against the couple's *actual* allocated budget for
  /// this category rather than where the vendor sits relative to its
  /// siblings — so this genuinely moves as the couple's entered budget
  /// amount moves, not just as the vendor pool happens to be priced.
  /// Reputation is deliberately left out here: [_finalScore] gives it its
  /// own dedicated weight per class, so folding it in again here would
  /// double-count it.
  static double _valueScore(VendorProfile v, BudgetClass bc, double? categoryBudget) {
    // A vendor with no price on file isn't "cheap" (that has to be earned by
    // an actual low price, or a confirmed-affordable vendor would lose to an
    // unpriced one purely for having no data) nor "expensive" — treat it as
    // sitting exactly on the budget line: neither a proven bargain nor a
    // proven splurge, so it can neither win nor lose a class's dominant
    // signal just for lacking data.
    final priceRatio = (categoryBudget != null && categoryBudget > 0 && v.priceMin > 0)
        ? v.priceMin / categoryBudget
        : 1.0;
    return switch (bc) {
      // How "premium" this looks relative to what the couple allocated —
      // only a light tiebreaker here since reputation already decides High
      // class almost entirely (see _finalScore).
      BudgetClass.highClass => priceRatio.clamp(0.0, 1.5) / 1.5,
      BudgetClass.flexible => (((v.rating ?? 0) / 5.0) + v.compositeScore / 100.0) / 2.0,
      // Cheaper relative to the couple's allocation wins outright; saturates
      // once price reaches the allocation itself — how far over that point
      // a vendor is gets penalized separately via overBudgetRatio.
      BudgetClass.budgetFriendly => (1.0 - priceRatio).clamp(0.0, 1.0),
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

  // Each wedding class has one deliberately dominant signal — a couple who
  // picked a class is telling the AI what to optimize for, so that signal
  // should decide the pick, not just nudge a three-way blend:
  //   - High class: reputation. "Premium only" means the best-reviewed
  //     vendor in the category wins, full stop — location/price are minor
  //     tiebreakers, not co-equal factors.
  //   - Flexible: a genuine balanced blend across reputation, price, and
  //     location — every reputation tier stays welcome and no one signal
  //     dominates.
  //   - Budget-friendly: price. The couple explicitly wants to spend less,
  //     so the cheapest-relative-to-their-allocation vendor wins outright,
  //     with reputation only as a light tiebreaker.
  // (Farther-but-cheaper vendors that lose out to a closer primary pick
  // aren't lost — see [_AiEngine.budgetAlternates], which surfaces the best
  // of those separately.)
  static double _finalScore(double rep, double loc, double val,
      BudgetClass bc, bool isBooked, double overBudgetRatio) {
    final base = switch (bc) {
      BudgetClass.highClass => rep * 0.75 + loc * 0.15 + val * 0.10,
      BudgetClass.flexible => rep * 0.30 + val * 0.30 + loc * 0.40,
      BudgetClass.budgetFriendly => val * 0.70 + loc * 0.15 + rep * 0.15,
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
    double locationScore,
  ) {
    final stars = v.rating?.toStringAsFixed(1) ?? '—';
    final rev = v.feedbackCount;
    final cat = v.category;

    final String budgetText;
    if (categoryBudget == null) {
      // Total budget is guaranteed to be set by this point (see the
      // NoBudgetSetException guard above) — this only fires for a custom
      // category the couple added that has no default allocation percentage,
      // so there's no per-category split to compare price against.
      budgetText = 'No specific allocation set for $cat yet, so price wasn\'t used as a filter here.';
    } else if (overBudgetRatio <= 0) {
      budgetText = 'Fits within your ~${categoryBudget.toStringAsFixed(0)} allocation for $cat.';
    } else {
      budgetText =
          'Starts around ${v.priceMin.toStringAsFixed(0)}, above your ~${categoryBudget.toStringAsFixed(0)} '
          'budget for $cat — still the closest available fit. You can move forward by asking for a '
          'smaller/custom package, trimming scope for $cat, or shifting budget from a lower-priority category.';
    }

    final reputationText = v.rating == null
        ? 'New to WedPilot — no client ratings yet, so this pick leaned on price and profile fit instead.'
        : '$stars★ from $rev verified ${rev == 1 ? 'client' : 'clients'}${(v.recommendRate != null && v.recommendRate! > 0) ? ', ${(v.recommendRate! * 100).round()}% would recommend' : ''}.';

    final availabilityText = isBooked
        ? 'Already booked on your wedding date — confirm availability before relying on them, or line up a backup in $cat.'
        : 'Open on your wedding date, based on their calendar.';

    // Proximity is treated as a high-priority factor, so it's always called
    // out plainly before style — the couple should know whether "near you"
    // is why this pick won, or whether it's a trade-off they should weigh.
    final locationName = (v.location?.isNotEmpty ?? false) ? v.location! : null;
    final String proximityText;
    if (locationName == null) {
      proximityText = '';
    } else if (locationScore >= 0.7) {
      proximityText = 'Located in $locationName — close to you, prioritized as a top match for proximity. ';
    } else if (locationScore <= 0.35) {
      proximityText = 'Located in $locationName — further from you, so this weighed against them here. ';
    } else {
      proximityText = 'Located in $locationName. ';
    }

    final overlap = styles
        .where((pref) => v.styleTags.any((tag) => tag.toLowerCase() == pref.toLowerCase()))
        .toList();
    final styleText = proximityText +
        (overlap.isNotEmpty
            ? 'Matches your ${overlap.join(', ')} style preference${overlap.length > 1 ? 's' : ''}.'
            : v.styleTags.isNotEmpty
                ? 'Known for ${v.styleTags.take(2).join(', ')} — no direct overlap with your stated style, but still strong in $cat.'
                : 'No style tags on file to compare against your preferences.');

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

    final steps = [
      ReasoningStep(label: ReasoningStep.budgetFit, text: budgetText),
      ReasoningStep(label: ReasoningStep.reputation, text: reputationText),
      ReasoningStep(label: ReasoningStep.availability, text: availabilityText),
      ReasoningStep(label: ReasoningStep.styleMatch, text: styleText),
      ReasoningStep(label: ReasoningStep.verdict, text: verdictText),
    ];

    return steps;
  }

  // A candidate needs to be at least this much farther (on the 0-1 location
  // score) than the primary pick before it's worth surfacing as a distinct
  // "not near you, but cheaper" alternative — otherwise it's not telling the
  // couple anything they don't already get from the primary pick.
  static const double _farEnoughToMatter = 0.25;

  /// For each category with a known primary pick, finds the best-value
  /// candidate that (a) actually fits the couple's allocated budget for that
  /// category and (b) is meaningfully farther away than the primary pick —
  /// i.e. exactly the vendor the primary's location-first weighting passed
  /// over. Purely local/deterministic (works the same whether the primary
  /// picks came from the LLM or the offline fallback) so it never depends on
  /// an extra AI call succeeding.
  static List<VendorMatch> budgetAlternates(
    List<_ScoredVendor> scored,
    List<VendorMatch> primaryMatches,
    Map<String, double> categoryBudgets,
  ) {
    final byCategory = <String, List<_ScoredVendor>>{};
    for (final s in scored) {
      byCategory.putIfAbsent(s.vendor.category, () => []).add(s);
    }
    final primaryByCategory = <String, VendorMatch>{
      for (final m in primaryMatches)
        if (m.rankInCategory == 1) m.vendor.category: m,
    };

    final alternates = <VendorMatch>[];
    for (final entry in byCategory.entries) {
      final primary = primaryByCategory[entry.key];
      final budget = categoryBudgets[entry.key];
      if (primary == null || budget == null || budget <= 0) continue;

      final candidates = entry.value.where((s) =>
          s.vendor.id != primary.vendorId &&
          s.vendor.priceMin > 0 &&
          s.vendor.priceMin <= budget &&
          (primary.locationScore - s.location) >= _farEnoughToMatter).toList();
      if (candidates.isEmpty) continue;

      candidates.sort((a, b) => b.finalScore.compareTo(a.finalScore));
      final alt = candidates.first;
      final locationName = (alt.vendor.location?.isNotEmpty ?? false)
          ? alt.vendor.location!
          : 'a different area';
      alternates.add(VendorMatch(
        vendorId: alt.vendor.id,
        vendor: alt.vendor,
        finalScore: alt.finalScore,
        reputationScore: alt.reputation,
        budgetScore: alt.value,
        locationScore: alt.location,
        availabilityScore: alt.isBookedOnWeddingDate ? 0.0 : 1.0,
        reasoning:
            'Not near you ($locationName), but fits your ~${budget.toStringAsFixed(0)} '
            'budget for ${entry.key} better than the closer options.',
        reasoningSteps: [
          ReasoningStep(
            label: ReasoningStep.verdict,
            text:
                'Located in $locationName — further from you, so it isn\'t the top pick, but it\'s '
                'the strongest budget fit for ${entry.key} at ~${budget.toStringAsFixed(0)}.',
          ),
        ],
        rankInCategory: 0,
        totalInCategory: primary.totalInCategory,
        kind: VendorMatchKind.budgetAlternate,
      ));
    }
    return alternates;
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
  final VendorPriceTier priceTier;
  const _ScoredVendor({
    required this.vendor,
    required this.reputation,
    required this.location,
    required this.value,
    required this.finalScore,
    this.isBookedOnWeddingDate = false,
    this.categoryBudget,
    this.overBudgetRatio = 0.0,
    this.priceTier = VendorPriceTier.mid,
  });
}

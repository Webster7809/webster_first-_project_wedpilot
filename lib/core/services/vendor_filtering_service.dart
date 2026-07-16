import '../../models/budget_class.dart';
import '../../models/vendor_profile.dart';

/// Step 1 of the pre-AI validation pipeline: narrows the full vendor pool
/// down to real candidates for the couple's requested categories and location.
/// Pure and stateless so both the validation pipeline and the AI ranking
/// engine can share one filtering implementation instead of duplicating it.
class VendorFilteringService {
  VendorFilteringService._();

  /// Every vendor in a requested category is always included in the pool —
  /// wedding class and star rating shape *ranking*, they never zero out a
  /// category outright here. A hard price-tier/rating gate used to mean a
  /// whole category could come back with nothing the moment no vendor
  /// cleared its bar, even when the category had plenty of real vendors the
  /// couple could see and afford. Ranking already degrades gracefully to the
  /// "closest available fit"; it just needs a non-empty pool to work with.
  static ({List<VendorProfile> pool, Map<String, VendorPriceTier> tiers}) filterEligible(
    List<VendorProfile> vendors,
    List<String> categories,
  ) {
    final pool = categories.isEmpty
        ? vendors
        : vendors.where((v) => categories.contains(v.category)).toList();
    final tiers = relativePriceTiers(pool);
    return (pool: pool, tiers: tiers);
  }

  /// Buckets each vendor into low/mid/high relative to other vendors in the
  /// *same category* who have actually entered pricing — a photographer and
  /// a venue are priced on completely different scales, so "premium" only
  /// means anything when compared within the same service type. Vendors
  /// without priced services yet (nothing to compare) fall back to their
  /// subscription tier as the best available signal.
  static Map<String, VendorPriceTier> relativePriceTiers(
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

  /// Narrows every category's candidates down to vendors actually based in
  /// the couple's entered location — a hard requirement, not a soft
  /// preference. There is no fallback to out-of-area vendors here: a
  /// category with nobody registered in the couple's location simply gets no
  /// pick rather than surfacing a vendor the couple never asked to be
  /// matched with. A category keeps its full vendor set only when the
  /// couple hasn't entered a location yet — there's nothing to filter
  /// against.
  static List<VendorProfile> restrictToLocation(
    List<VendorProfile> pool,
    String? coupleLocation,
  ) {
    final target = coupleLocation?.toLowerCase().trim();
    if (target == null || target.isEmpty) return pool;
    return pool.where((v) => locationMatches(v.location, target)).toList();
  }

  static bool locationMatches(String? vendorLocation, String targetLower) {
    if (vendorLocation == null || vendorLocation.trim().isEmpty) return false;
    final v = vendorLocation.toLowerCase().trim();
    return v == targetLower || v.contains(targetLower) || targetLower.contains(v);
  }

  /// Groups an already location/category-filtered pool by category — the
  /// shape every downstream validation stage (coverage, budget realism,
  /// combination) and the AI engine itself needs to reason per-category.
  static Map<String, List<VendorProfile>> groupByCategory(
    List<VendorProfile> pool,
    List<String> categories,
  ) {
    final byCategory = <String, List<VendorProfile>>{};
    for (final cat in categories) {
      byCategory[cat] = pool.where((v) => v.category == cat).toList();
    }
    return byCategory;
  }

  /// Narrows each category to the vendors matching the couple's wedding
  /// class's rating band before picking: High class prefers 4.5★+ vendors,
  /// Budget-friendly prefers vendors under 4.5★ or with no rating yet, and
  /// Flexible has no rating preference (either band is fine). A category
  /// with nobody in the matching band falls back to its full vendor list
  /// rather than coming back empty — wedding class is a soft preference for
  /// picking, never a reason to show nothing.
  static Map<String, List<VendorProfile>> preferredByWeddingClass(
    Map<String, List<VendorProfile>> byCategory,
    BudgetClass budgetClass,
  ) {
    bool matches(VendorProfile v) => switch (budgetClass) {
          BudgetClass.highClass => (v.rating ?? 0) >= 4.5,
          BudgetClass.budgetFriendly => v.rating == null || v.rating! < 4.5,
          BudgetClass.flexible => true,
        };

    return {
      for (final entry in byCategory.entries)
        entry.key: (() {
          final preferred = entry.value.where(matches).toList();
          return preferred.isEmpty ? entry.value : preferred;
        })(),
    };
  }
}

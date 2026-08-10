import '../../models/budget_class.dart';
import '../../models/vendor_profile.dart';
import 'vendor_class_service.dart';

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
  /// class, in two graceful layers — both of them a strict partition, so a
  /// vendor belongs to exactly one class and can never surface as a pick
  /// under more than one:
  ///
  /// 1. Vendors who have genuinely *earned* the couple's class per
  ///    [VendorClassService.classify] — verification, rating track record,
  ///    and a registered qualifying package. `classify` itself already
  ///    returns exactly one class per vendor (High Class first, then
  ///    Flexible, else Budget-Friendly), so this layer alone guarantees no
  ///    overlap: a vendor good enough to have earned High Class is *only*
  ///    in the High Class pool, never Flexible's or Budget-Friendly's too.
  /// 2. Failing that, the class's star-rating band (High → 4.5★+,
  ///    Flexible → 3.5★–4.5★, Budget-friendly → under 3.5★ or unrated) —
  ///    same partition, just on the raw rating, so young marketplaces where
  ///    nobody has earned a class yet still rank sensibly without doubling
  ///    a vendor up across bands.
  ///
  /// A category with nobody in either layer falls back to its full vendor
  /// list rather than coming back empty — wedding class is a soft preference
  /// for picking, never a reason to show nothing. In practice this only
  /// happens for a category with no class-earning coverage at all — the
  /// seeded curated vendors (backend/scripts/seedCuratedVendors.js) guarantee
  /// every built-in category has real earners for every class.
  /// Hard-excludes any vendor already booked on the couple's wedding date,
  /// per category — "availability" is one of the things every recommendation
  /// must satisfy, not just a scoring penalty. Falls back to the unfiltered
  /// category list when the exclusion would otherwise empty it out, same
  /// graceful-degrade shape as [preferredByWeddingClass]: a date conflict on
  /// every vendor in a category is never a reason to show the couple
  /// nothing — [_AiEngine._finalScore]'s booked-vendor penalty still demotes
  /// them within that fallback case.
  static Map<String, List<VendorProfile>> excludeBookedOnDate(
    Map<String, List<VendorProfile>> byCategory,
    String? weddingDateStr,
  ) {
    if (weddingDateStr == null || weddingDateStr.isEmpty) return byCategory;

    bool isBooked(VendorProfile v) => v.blockedDates.contains(weddingDateStr);

    return {
      for (final entry in byCategory.entries)
        entry.key: (() {
          final available = entry.value.where((v) => !isBooked(v)).toList();
          return available.isEmpty ? entry.value : available;
        })(),
    };
  }

  static Map<String, List<VendorProfile>> preferredByWeddingClass(
    Map<String, List<VendorProfile>> byCategory,
    BudgetClass budgetClass,
  ) {
    bool bandMatches(VendorProfile v) {
      final rating = v.rating ?? 0;
      return switch (budgetClass) {
        BudgetClass.highClass => rating >= 4.5,
        BudgetClass.flexible => rating >= 3.5 && rating < 4.5,
        BudgetClass.budgetFriendly => v.rating == null || rating < 3.5,
      };
    }

    bool earnedClass(VendorProfile v) =>
        VendorClassService.classify(v) == budgetClass;

    return {
      for (final entry in byCategory.entries)
        entry.key: (() {
          final earned = entry.value.where(earnedClass).toList();
          if (earned.isNotEmpty) return earned;
          final band = entry.value.where(bandMatches).toList();
          return band.isEmpty ? entry.value : band;
        })(),
    };
  }
}

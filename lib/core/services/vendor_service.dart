import '../../models/vendor_profile.dart';

class VendorService {
  VendorService._();

  // ── Filtering ────────────────────────────────────────────────────────────────

  static List<VendorProfile> filterByCategory(
      List<VendorProfile> vendors, String category) {
    if (category == 'All') return vendors;
    return vendors.where((v) => v.category == category).toList();
  }

  static List<VendorProfile> filterByBudget(
      List<VendorProfile> vendors, double maxBudget) {
    return vendors.where((v) => v.priceMin <= maxBudget).toList();
  }

  static List<VendorProfile> filterBySearchQuery(
      List<VendorProfile> vendors, String query) {
    if (query.trim().isEmpty) return vendors;
    final q = query.toLowerCase();
    return vendors
        .where((v) =>
            v.businessName.toLowerCase().contains(q) ||
            (v.description?.toLowerCase().contains(q) ?? false) ||
            v.category.toLowerCase().contains(q) ||
            v.styleTags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  // ── Ranking ──────────────────────────────────────────────────────────────────

  /// Ranks vendors by a composite score.
  /// If budgetAmount is provided: 60 % reputation + 40 % budget fit.
  /// Otherwise: pure reputation (rating).
  static List<VendorProfile> rankByScore(
    List<VendorProfile> vendors, {
    double? budgetAmount,
  }) {
    if (vendors.isEmpty) return vendors;

    if (budgetAmount == null) {
      return [...vendors]
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    }

    double budgetScore(VendorProfile v) {
      if (v.priceMin > budgetAmount) return 0.0;
      if (v.priceMax <= budgetAmount) return 1.0;
      final range = v.priceMax - v.priceMin;
      return range > 0 ? (budgetAmount - v.priceMin) / range : 1.0;
    }

    final scored = vendors.map((v) {
      final reputation = (v.rating ?? 0) / 5.0;
      final budgetFit = budgetScore(v);
      return (vendor: v, score: reputation * 0.6 + budgetFit * 0.4);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.map((e) => e.vendor).toList();
  }

  // ── Recommendations ──────────────────────────────────────────────────────────

  /// Returns up to [limit] best vendors for a given category and budget.
  static List<VendorProfile> recommend(
    List<VendorProfile> vendors, {
    required String category,
    double? categoryBudget,
    int limit = 3,
  }) {
    final byCat = filterByCategory(vendors, category);
    final candidates = categoryBudget != null
        ? filterByBudget(byCat, categoryBudget)
        : byCat;
    final pool = candidates.isEmpty ? byCat : candidates;
    return rankByScore(pool, budgetAmount: categoryBudget).take(limit).toList();
  }

  /// Budget-fit label shown in reports.
  static String budgetFitLabel(VendorProfile vendor, double? budget) {
    if (budget == null) return 'No budget set';
    if (vendor.priceMin > budget) return 'Over budget';
    if (vendor.priceMax <= budget) return 'Well within budget';
    return 'Partially within budget';
  }

  // ── Stats for reports ────────────────────────────────────────────────────────

  static VendorReportData buildReport(
    List<VendorProfile> vendors,
    double? totalBudget,
  ) {
    final byCategory = <String, List<VendorProfile>>{};
    for (final v in vendors) {
      byCategory.putIfAbsent(v.category, () => []).add(v);
    }

    final withinBudget = totalBudget == null
        ? <VendorProfile>[]
        : vendors.where((v) => v.priceMin <= totalBudget).toList();

    final topRated = [...vendors]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    return VendorReportData(
      totalVendors: vendors.length,
      categoriesCovered: byCategory.keys.toList(),
      vendorsByCategory: byCategory,
      withinBudgetCount: withinBudget.length,
      topRated: topRated.take(3).toList(),
      averageRating: vendors.isEmpty
          ? 0.0
          : vendors.fold<double>(0, (s, v) => s + (v.rating ?? 0)) / vendors.length,
    );
  }
}

class VendorReportData {
  final int totalVendors;
  final List<String> categoriesCovered;
  final Map<String, List<VendorProfile>> vendorsByCategory;
  final int withinBudgetCount;
  final List<VendorProfile> topRated;
  final double averageRating;

  const VendorReportData({
    required this.totalVendors,
    required this.categoriesCovered,
    required this.vendorsByCategory,
    required this.withinBudgetCount,
    required this.topRated,
    required this.averageRating,
  });
}

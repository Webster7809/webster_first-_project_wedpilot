import '../../models/budget_class.dart';
import '../../models/vendor_profile.dart';

/// One requirement on the road to a wedding class, with whether this vendor
/// currently meets it — rendered as a checklist so a vendor can see exactly
/// what stands between them and the next class.
class ClassCriterion {
  final String label;
  final bool met;
  const ClassCriterion(this.label, this.met);
}

/// The single source of truth for how a vendor qualifies as Budget-Friendly,
/// Flexible, or High Class. Every vendor starts Budget-Friendly; the higher
/// classes are earned, never self-declared:
///
/// **Flexible** — all of:
///   1. Verified by the WedPilot admin team
///   2. Average rating of 3.5★ or higher
///   3. At least 3 verified client reviews
///   4. At least one package registered (starter or luxury)
///
/// **High Class** — all of:
///   1. Verified by the WedPilot admin team
///   2. Average rating of 4.5★ or higher
///   3. At least 10 verified client reviews
///   4. At least 90% of clients would recommend them
///   5. A luxury package registered with 3+ inclusions
///
/// Everything here is computed from data the vendor cannot edit directly
/// (admin verification, couples' feedback) plus the packages they register —
/// so the class is a genuine track record, not a checkbox.
class VendorClassService {
  VendorClassService._();

  static const double highClassMinRating = 4.5;
  static const int highClassMinReviews = 10;
  static const double highClassMinRecommendRate = 0.9;
  static const int luxuryPackageMinInclusions = 3;

  static const double flexibleMinRating = 3.5;
  static const int flexibleMinReviews = 3;

  static bool _hasLuxuryPackage(VendorProfile v) => v.packages.any((p) =>
      p.tier == VendorPackageTier.luxury &&
      p.inclusions.length >= luxuryPackageMinInclusions);

  static bool _hasAnyPackage(VendorProfile v) =>
      v.packages.any((p) => p.inclusions.isNotEmpty);

  static List<ClassCriterion> highClassCriteria(VendorProfile v) => [
        ClassCriterion('Verified by WedPilot admin', v.isVerified),
        ClassCriterion(
          'Average rating of ${highClassMinRating.toStringAsFixed(1)}★ or higher',
          (v.rating ?? 0) >= highClassMinRating,
        ),
        ClassCriterion(
          'At least $highClassMinReviews verified client reviews',
          v.feedbackCount >= highClassMinReviews,
        ),
        ClassCriterion(
          'At least ${(highClassMinRecommendRate * 100).round()}% of clients recommend you',
          (v.recommendRate ?? 0) >= highClassMinRecommendRate,
        ),
        ClassCriterion(
          'Luxury package registered ($luxuryPackageMinInclusions+ inclusions)',
          _hasLuxuryPackage(v),
        ),
      ];

  static List<ClassCriterion> flexibleCriteria(VendorProfile v) => [
        ClassCriterion('Verified by WedPilot admin', v.isVerified),
        ClassCriterion(
          'Average rating of ${flexibleMinRating.toStringAsFixed(1)}★ or higher',
          (v.rating ?? 0) >= flexibleMinRating,
        ),
        ClassCriterion(
          'At least $flexibleMinReviews verified client reviews',
          v.feedbackCount >= flexibleMinReviews,
        ),
        ClassCriterion(
          'At least one package registered (starter or luxury)',
          _hasAnyPackage(v),
        ),
      ];

  static bool _meetsAll(List<ClassCriterion> criteria) =>
      criteria.every((c) => c.met);

  /// The class this vendor has actually earned right now.
  static BudgetClass classify(VendorProfile v) {
    if (_meetsAll(highClassCriteria(v))) return BudgetClass.highClass;
    if (_meetsAll(flexibleCriteria(v))) return BudgetClass.flexible;
    return BudgetClass.budgetFriendly;
  }
}

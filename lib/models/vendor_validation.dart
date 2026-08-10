import 'messaging.dart';
import 'vendor_profile.dart';

/// A category the couple has already sent a booking request for, together with
/// the vendor and the request itself.
///
/// The matcher skips these categories entirely rather than re-picking them: a
/// vendor the couple already committed to must never be quietly swapped for
/// someone else on the next run, and the already-requested vendor must never
/// be proposed a second time.
class LockedCategoryRequest {
  final VendorProfile vendor;
  final Inquiry inquiry;

  const LockedCategoryRequest({required this.vendor, required this.inquiry});
}

/// Which validation stage produced a whole-plan rejection — lets the UI (or a
/// future analytics hook) branch on failure kind without string-matching
/// [VendorValidationFailure.message].
enum VendorValidationFailureType {
  noVendorsInLocation,
  budgetTooLowForAnyVendor,
  noVendorCapacityForGuestCount,
}

class VendorValidationFailure {
  final VendorValidationFailureType type;
  final String message;

  const VendorValidationFailure({required this.type, required this.message});
}

/// Result of running the pre-AI validation pipeline (location coverage and
/// per-category vendor coverage) against the couple's real vendor pool. A
/// non-null [blockingFailure] means the AI must never be called — see
/// [VendorValidationException].
class VendorValidationResult {
  /// Whole-plan stop. Null means every hard-gated stage passed.
  final VendorValidationFailure? blockingFailure;

  /// Location-filtered vendor pool per requested category, excluding any
  /// category with zero vendors in the couple's location (see
  /// [excludedCategoryMessages] for why those are missing).
  final Map<String, List<VendorProfile>> byCategory;
  final Map<String, VendorPriceTier> tiers;

  /// Each category's usable spend — the real money left in the couple's
  /// budget by the time this category is funded, in wizard order (see
  /// `vendorMatchValidationProvider`'s sequential allocation). Never a fixed
  /// percentage or proportional split; it's the actual running balance.
  final Map<String, double> categoryBudgets;

  /// One message per category that has zero vendors in the couple's location
  /// — a soft, single-category exclusion (the couple can still add their own
  /// vendor for it) rather than a whole-plan [blockingFailure].
  final Map<String, String> excludedCategoryMessages;

  /// One message per category the couple's budget ran out before reaching —
  /// the categories before it in wizard order already spent the money that
  /// would have funded it. Also a soft, single-category message, not a
  /// whole-plan [blockingFailure]: earlier categories still get real picks.
  final Map<String, String> budgetExhaustedMessages;

  /// One message per category where vendors exist in the couple's location
  /// but none of them state enough capacity for the couple's guest count
  /// (see [VendorProfile.canServeGuestCount]). Also soft/single-category,
  /// never a whole-plan [blockingFailure] — and never conflated with
  /// [budgetExhaustedMessages], since money isn't the constraint here.
  final Map<String, String> guestCapacityExcludedMessages;

  /// Categories the couple already has a live booking request in, keyed by
  /// category. These never reach scoring at all — the request itself is the
  /// answer for that category, so re-running the plan fills only what's still
  /// undecided. Freed automatically once a request is declined or cancelled.
  final Map<String, LockedCategoryRequest> lockedCategories;

  const VendorValidationResult({
    this.blockingFailure,
    this.byCategory = const {},
    this.tiers = const {},
    this.categoryBudgets = const {},
    this.excludedCategoryMessages = const {},
    this.budgetExhaustedMessages = const {},
    this.guestCapacityExcludedMessages = const {},
    this.lockedCategories = const {},
  });

  bool get isBlocked => blockingFailure != null;
}

/// Thrown by [aiRecommendedVendorsProvider] when a validation stage rejects
/// the couple's requirements outright — the AI must never run when this is
/// thrown (see CLAUDE.md's budget-validation architecture requirements).
class VendorValidationException implements Exception {
  final VendorValidationFailure failure;

  const VendorValidationException(this.failure);
}

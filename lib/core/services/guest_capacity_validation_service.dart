import '../../models/vendor_profile.dart';

/// Pre-AI validation pipeline stage: narrows each category's pool to vendors
/// who can seat the couple's guest count (see [VendorProfile.canServeGuestCount]).
/// A category with nobody able to seat the party is a soft, single-category
/// exclusion — never a whole-plan stop — mirroring
/// [BudgetValidationService.validateCoverage] exactly, just gated on stated
/// capacity instead of location presence.
///
/// Deliberately price-blind: this runs before the budget-funding pass, so a
/// big-enough-but-unaffordable vendor is left in the pool for the *existing*
/// budget-exhaustion messaging to explain (raising the budget can fix that).
/// This stage only excludes a category when literally nobody there states
/// enough capacity regardless of price — where more budget wouldn't help.
class GuestCapacityValidationService {
  GuestCapacityValidationService._();

  static ({
    Map<String, List<VendorProfile>> covered,
    Map<String, String> excludedMessages,
  }) validate({
    required Map<String, List<VendorProfile>> byCategory,
    required int? guestCount,
    required String? location,
  }) {
    if (guestCount == null || guestCount <= 0) {
      return (covered: byCategory, excludedMessages: const {});
    }

    final covered = <String, List<VendorProfile>>{};
    final excluded = <String, String>{};
    for (final entry in byCategory.entries) {
      final capable =
          entry.value.where((v) => v.canServeGuestCount(guestCount)).toList();
      if (capable.isEmpty) {
        final where = (location != null && location.trim().isNotEmpty)
            ? location.trim()
            : 'your selected location';
        excluded[entry.key] = 'No ${entry.key} vendors in $where state a serving '
            'capacity of $guestCount guests or more. Reduce your guest count, or '
            'ask a vendor directly about a custom package.';
      } else {
        covered[entry.key] = capable;
      }
    }
    return (covered: covered, excludedMessages: excluded);
  }
}

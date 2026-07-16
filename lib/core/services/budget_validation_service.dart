import '../../models/vendor_profile.dart';

/// Step 4 of the pre-AI validation pipeline: per-category coverage. A
/// category with zero vendors in the couple's location is a soft, single-
/// category exclusion — a couple can always add their own vendor for a
/// category nobody has registered yet — never a whole-plan stop.
class BudgetValidationService {
  BudgetValidationService._();

  /// Splits [byCategory] into vendors that actually have someone in the
  /// couple's location (kept) vs. categories with nobody there at all
  /// (reported via a message but not a [VendorValidationFailure] — the
  /// couple can still self-supply a vendor for just that category).
  static ({
    Map<String, List<VendorProfile>> covered,
    Map<String, String> excludedMessages,
  }) validateCoverage({
    required Map<String, List<VendorProfile>> byCategory,
    required String? location,
  }) {
    final covered = <String, List<VendorProfile>>{};
    final excluded = <String, String>{};
    for (final entry in byCategory.entries) {
      if (entry.value.isEmpty) {
        final where = (location != null && location.trim().isNotEmpty)
            ? location.trim()
            : 'your selected location';
        excluded[entry.key] = 'No ${entry.key} vendors are currently available in '
            '$where. Please remove this service or select another location.';
      } else {
        covered[entry.key] = entry.value;
      }
    }
    return (covered: covered, excludedMessages: excluded);
  }
}

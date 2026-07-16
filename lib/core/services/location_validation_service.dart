import '../../models/vendor_profile.dart';
import '../../models/vendor_validation.dart';

/// Step 2 of the pre-AI validation pipeline: a couple's entered location must
/// have at least one real vendor in it, across any of their requested
/// categories, before anything else is worth checking. Distinct from
/// per-category coverage (a soft, single-category exclusion) — this is a
/// whole-plan stop, since there's nothing at all to build a plan from.
class LocationValidationService {
  LocationValidationService._();

  static VendorValidationFailure? validate({
    required List<VendorProfile> locationFilteredPool,
    required String? location,
  }) {
    if (location == null || location.trim().isEmpty) return null;
    if (locationFilteredPool.isNotEmpty) return null;

    return VendorValidationFailure(
      type: VendorValidationFailureType.noVendorsInLocation,
      message: 'No vendors are currently available in your selected location '
          '($location). Please choose another location or modify your wedding '
          'requirements.',
    );
  }
}

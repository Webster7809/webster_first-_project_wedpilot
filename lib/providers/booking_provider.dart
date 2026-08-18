import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/vendor_api_service.dart';
import '../core/utils/inquiry_status_display.dart';
import '../models/messaging.dart';
import '../models/vendor_profile.dart';
import 'auth_provider.dart';

/// A couple's own sent booking requests/inquiries — status, decline reason,
/// and rating eligibility. Invalidated after a feedback submission so the
/// "Rate this vendor" prompt disappears once it's been acted on.
final myBookingsProvider = FutureProvider<List<Inquiry>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return VendorApiService.instance.fetchMyBookings(token);
});

/// Vendors the couple can actually leave feedback for right now — mirrors
/// the same `canRate` rule shown on my_bookings_screen.dart's "Rate this
/// vendor" button (status booked, service marked done, not yet rated) —
/// resolved to full profiles the same individual-fetch way
/// wishlistedVendorsProvider does, so this is never subject to the vendor
/// directory's page cap and never confuses "booked" with "wishlisted."
final rateableVendorsProvider = FutureProvider<List<VendorProfile>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  final bookings = await ref.watch(myBookingsProvider.future);
  final vendorIds = {
    for (final b in bookings)
      if (b.status == InquiryStatus.booked &&
          b.serviceDoneAt != null &&
          !b.hasFeedback)
        b.vendorId,
  };
  if (vendorIds.isEmpty) return [];

  final results = await Future.wait(
    vendorIds.map((id) async {
      try {
        return await VendorApiService.instance.fetchVendorDetail(token, id);
      } catch (_) {
        return null;
      }
    }),
  );
  return results.whereType<VendorProfile>().toList();
});

/// Vendors the couple currently has a live request with, keyed by vendor id —
/// anything not declined or cancelled (see [InquiryStatusDisplay.isActive]).
///
/// Derived from [myBookingsProvider] rather than fetching again, so it stays
/// consistent with every other booking surface and refreshes from the same
/// single invalidation.
///
/// This is what stops the AI re-proposing a vendor the couple already
/// committed to: the matcher subtracts these before it scores anything, so a
/// decision the couple already made is never silently re-made for them.
/// Where the same vendor has several rows (older declined ones, say), the most
/// recent live request wins.
final activeRequestsByVendorProvider =
    FutureProvider<Map<String, Inquiry>>((ref) async {
  final bookings = await ref.watch(myBookingsProvider.future);
  final active = bookings
      .where((b) => InquiryStatusDisplay.isActive(b.status))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  // Ascending sort + plain assignment means the newest row for a vendor is the
  // one left in the map.
  return {for (final b in active) b.vendorId: b};
});

/// Vendor ids the automatic "rate this vendor" popup has already been shown
/// for this app session — so each one surfaces once per launch rather than
/// every time the dashboard rebuilds, without a single global flag silently
/// swallowing every vendor after the first. A couple with two weddings-worth
/// of vendors wrapping up around the same time still gets one prompt per
/// vendor, not just one prompt total. Resets naturally on app restart, which
/// is fine: if there's still something to rate, it's worth surfacing again
/// next time.
final ratePromptShownProvider = StateProvider<Set<String>>((ref) => {});

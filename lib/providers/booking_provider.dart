import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/vendor_api_service.dart';
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

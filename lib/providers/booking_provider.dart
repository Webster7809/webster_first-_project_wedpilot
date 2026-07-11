import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/vendor_api_service.dart';
import '../models/messaging.dart';
import 'auth_provider.dart';

/// A couple's own sent booking requests/inquiries — status, decline reason,
/// and rating eligibility. Invalidated after a feedback submission so the
/// "Rate this vendor" prompt disappears once it's been acted on.
final myBookingsProvider = FutureProvider<List<Inquiry>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return VendorApiService.instance.fetchMyBookings(token);
});

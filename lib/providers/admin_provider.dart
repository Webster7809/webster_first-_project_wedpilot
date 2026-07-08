import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/admin_api_service.dart';
import '../models/admin_models.dart';
export '../models/admin_models.dart';
import 'auth_provider.dart';

String? _token(Ref ref) => ref.watch(authProvider.notifier).accessToken;

final adminOverviewProvider = FutureProvider<AdminOverview>((ref) async {
  final token = _token(ref);
  if (token == null) {
    return const AdminOverview(
      activeCouples: 0,
      registeredVendors: 0,
      pendingVendorsCount: 0,
      verificationRate: 100,
      invitationsSentThisWeek: 0,
    );
  }
  return AdminApiService.instance.fetchOverview(token);
});

final adminPendingVendorsProvider = FutureProvider<List<AdminVendor>>((ref) async {
  final token = _token(ref);
  if (token == null) return [];
  return AdminApiService.instance.fetchPendingVendors(token);
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final token = _token(ref);
  if (token == null) return [];
  return AdminApiService.instance.fetchUsers(token);
});

final adminFlaggedReviewsProvider = FutureProvider<List<FlaggedReview>>((ref) async {
  final token = _token(ref);
  if (token == null) return [];
  return AdminApiService.instance.fetchFlaggedReviews(token);
});

final adminFlaggedImagesProvider = FutureProvider<List<FlaggedImage>>((ref) async {
  final token = _token(ref);
  if (token == null) return [];
  return AdminApiService.instance.fetchFlaggedImages(token);
});

/// Always resolves empty — no messaging system exists yet to flag from.
final adminFlaggedMessagesProvider = FutureProvider<List<FlaggedMessage>>((ref) async {
  final token = _token(ref);
  if (token == null) return [];
  return AdminApiService.instance.fetchFlaggedMessages(token);
});

final adminAnalyticsProvider = FutureProvider<AdminAnalytics>((ref) async {
  final token = _token(ref);
  if (token == null) {
    return const AdminAnalytics(
      userGrowthWeek: [0, 0, 0, 0, 0, 0, 0],
      userGrowthMonth: [0, 0, 0, 0],
      userGrowthYear: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      vendorTierDistribution: {'free': 0, 'pro': 0, 'premium': 0},
      topCategories: [],
    );
  }
  return AdminApiService.instance.fetchAnalytics(token);
});


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_api_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return NotificationApiService.instance.fetchNotifications(token);
});

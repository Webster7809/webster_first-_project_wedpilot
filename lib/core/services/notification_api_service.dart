import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../../models/notification_model.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend.

class NotificationApiException implements Exception {
  final String message;
  const NotificationApiException(this.message);
}

class NotificationApiService {
  NotificationApiService._();
  static final NotificationApiService instance = NotificationApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  Future<List<NotificationModel>> fetchNotifications(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/notifications',
        options: _auth(accessToken),
      );
      final list = (response.data?['notifications'] as List?) ?? [];
      return list
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  Future<void> markRead(String accessToken, String notifId) async {
    try {
      await _dio.patch(
        '/api/notifications/$notifId/read',
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  Future<void> markAllRead(String accessToken) async {
    try {
      await _dio.patch(
        '/api/notifications/read-all',
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}

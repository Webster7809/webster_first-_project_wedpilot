import 'package:dio/dio.dart';

import '../../models/notification_model.dart';
import 'api_error.dart';
import 'authenticated_dio.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend.

class NotificationApiException implements Exception {
  final String message;
  const NotificationApiException(this.message);
}

class NotificationApiService {
  NotificationApiService._();
  static final NotificationApiService instance = NotificationApiService._();

  final Dio _dio = buildApiDio();

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

  Future<void> deleteNotification(String accessToken, String notifId) async {
    try {
      await _dio.delete(
        '/api/notifications/$notifId',
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  /// Clears every already-read notification in one action. Unread ones are
  /// left alone — deleting something the couple hasn't seen yet would be
  /// surprising.
  Future<void> clearRead(String accessToken) async {
    try {
      await _dio.delete(
        '/api/notifications',
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) => describeDioError(e);
}

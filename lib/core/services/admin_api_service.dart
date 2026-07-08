import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/admin_models.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend at [_baseUrl].
const int _backendPort = 3000;
const String? _lanHost = null;

String get _baseUrl {
  if (_lanHost != null) return 'http://$_lanHost:$_backendPort';
  if (kIsWeb) return 'http://localhost:$_backendPort';
  if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort';
  return 'http://localhost:$_backendPort';
}

class AdminApiException implements Exception {
  final String message;
  const AdminApiException(this.message);
}

class AdminApiService {
  AdminApiService._();
  static final AdminApiService instance = AdminApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  Future<AdminOverview> fetchOverview(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/admin/overview',
        options: _auth(accessToken),
      );
      return AdminOverview.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<List<AdminVendor>> fetchPendingVendors(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/admin/vendors/pending',
        options: _auth(accessToken),
      );
      final list = (response.data?['vendors'] as List?) ?? [];
      return list.map((v) => AdminVendor.fromJson(v as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<void> setVendorVerification(
    String accessToken,
    String vendorId, {
    required String status,
    String? note,
  }) async {
    try {
      await _dio.patch(
        '/api/admin/vendors/$vendorId/verification',
        data: {'status': status, 'note': note},
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<List<AdminUser>> fetchUsers(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/admin/users',
        options: _auth(accessToken),
      );
      final list = (response.data?['users'] as List?) ?? [];
      return list.map((u) => AdminUser.fromJson(u as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<void> setUserSuspended(String accessToken, String userId, bool suspended) async {
    try {
      await _dio.patch(
        '/api/admin/users/$userId/suspend',
        data: {'suspended': suspended},
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<void> deleteUser(String accessToken, String userId) async {
    try {
      await _dio.delete('/api/admin/users/$userId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<List<FlaggedReview>> fetchFlaggedReviews(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/admin/moderation/reviews',
        options: _auth(accessToken),
      );
      final list = (response.data?['reviews'] as List?) ?? [];
      return list.map((r) => FlaggedReview.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<void> moderateReview(String accessToken, String reviewId, {required String action}) async {
    try {
      await _dio.patch(
        '/api/admin/moderation/reviews/$reviewId',
        data: {'action': action},
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<List<FlaggedImage>> fetchFlaggedImages(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/admin/moderation/images',
        options: _auth(accessToken),
      );
      final list = (response.data?['images'] as List?) ?? [];
      return list.map((i) => FlaggedImage.fromJson(i as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<void> moderateImage(String accessToken, String mediaId, {required String action}) async {
    try {
      await _dio.patch(
        '/api/admin/moderation/images/$mediaId',
        data: {'action': action},
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  /// Always empty today — no messaging system exists yet to flag from.
  Future<List<FlaggedMessage>> fetchFlaggedMessages(String accessToken) async {
    try {
      await _dio.get<Map<String, dynamic>>(
        '/api/admin/moderation/messages',
        options: _auth(accessToken),
      );
      return const [];
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  Future<AdminAnalytics> fetchAnalytics(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/admin/analytics',
        options: _auth(accessToken),
      );
      return AdminAnalytics.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw AdminApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}

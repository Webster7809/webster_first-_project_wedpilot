import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/couple_profile.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend at [_baseUrl].
// Change [_backendPort] or [_lanHost] when deploying to production.
const int _backendPort = 3000;

// Set this to your machine's LAN IP (e.g. '192.168.1.20') when testing on a
// physical device, since 'localhost' on the device refers to the device itself.
const String? _lanHost = null;

String get _baseUrl {
  if (_lanHost != null) return 'http://$_lanHost:$_backendPort';
  if (kIsWeb) return 'http://localhost:$_backendPort';
  if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort'; // Android emulator → host localhost
  return 'http://localhost:$_backendPort'; // iOS simulator, desktop
}

class CoupleProfileApiException implements Exception {
  final String message;
  const CoupleProfileApiException(this.message);
}

class CoupleProfileService {
  CoupleProfileService._();
  static final CoupleProfileService instance = CoupleProfileService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Returns `null` if the couple hasn't saved a profile yet (404 — expected).
  Future<CoupleProfile?> fetchProfile(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/couple/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data ?? {};
      return CoupleProfile.fromJson(data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw CoupleProfileApiException(_extractError(e));
    }
  }

  Future<CoupleProfile> saveProfile(String accessToken, CoupleProfile profile) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/couple/profile',
        data: profile.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data ?? {};
      return CoupleProfile.fromJson(data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw CoupleProfileApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}

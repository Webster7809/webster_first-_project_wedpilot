import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/user.dart';

// Flutter never touches the database directly.
// All auth calls go through the Node/Express backend at [_baseUrl].
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

class AuthApiException implements Exception {
  final String message;
  const AuthApiException(this.message);
}

class AuthResult {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiry;
  final DateTime refreshExpiry;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiry,
    required this.refreshExpiry,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessExpiry: DateTime.parse(json['accessExpiry'] as String),
        refreshExpiry: DateTime.parse(json['refreshExpiry'] as String),
      );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return _postAuth('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role.name,
    });
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _postAuth('/api/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<User> fetchCurrentUser(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data ?? {};
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthApiException(_extractError(e));
    }
  }

  Future<AuthResult> _postAuth(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return AuthResult.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw AuthApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}

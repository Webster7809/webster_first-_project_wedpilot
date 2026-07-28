import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../../models/user.dart';

// Flutter never touches the database directly.
// All auth calls go through the Node/Express backend.

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
    baseUrl: ApiConfig.baseUrl,
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

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractError(e));
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
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

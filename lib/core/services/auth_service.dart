import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../../models/user.dart';
import 'api_error.dart';

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
    String? phone,
  }) async {
    return _postAuth('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role.name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
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

  /// Exchanges a still-valid refresh token for a fresh access/refresh pair.
  /// Used by [SessionManager] once the short-lived access token expires
  /// mid-session, rather than forcing a full re-login every hour.
  Future<AuthResult> refresh(String refreshToken) async {
    return _postAuth('/api/auth/refresh', {'refreshToken': refreshToken});
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

  /// Asks the backend to mail a fresh confirmation link to the signed-in
  /// account's own address — hence the access token rather than an email
  /// parameter.
  Future<void> resendVerificationEmail(String accessToken) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/resend-verification',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractError(e));
    }
  }

  /// Redeems the token from a confirmation link. Unauthenticated: the link is
  /// opened by whatever browser the user's mail client hands it to.
  Future<void> verifyEmail(String token) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/verify-email',
        data: {'token': token},
      );
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

  /// Changes the signed-in user's password. Requires the current one — a
  /// stolen-but-not-yet-expired access token should not be enough on its own
  /// to lock the real owner out.
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractError(e));
    }
  }

  /// Syncs the Email Notifications toggle server-side so it actually gates
  /// the notification emails sent from the backend, not just the local copy
  /// in [SettingsNotifier].
  Future<void> updateNotificationPreferences({
    required String accessToken,
    required bool emailNotifications,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/auth/notification-preferences',
        data: {'emailNotifications': emailNotifications},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw AuthApiException(_extractError(e));
    }
  }

  /// Permanently deactivates the signed-in account. Requires the current
  /// password, same reasoning as [changePassword] — an irreversible action
  /// like this needs more than a still-valid session token.
  Future<void> deleteAccount({
    required String accessToken,
    required String currentPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/delete-account',
        data: {'currentPassword': currentPassword},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
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

  String _extractError(DioException e) => describeDioError(e);
}

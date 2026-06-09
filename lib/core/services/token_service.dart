import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';
const _kAccessExpiry = 'access_expiry';
const _kRefreshExpiry = 'refresh_expiry';

class TokenService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessExpiry,
    required DateTime refreshExpiry,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kAccessExpiry, value: accessExpiry.toIso8601String()),
      _storage.write(key: _kRefreshExpiry, value: refreshExpiry.toIso8601String()),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<bool> isAccessTokenValid() async {
    final expiry = await _storage.read(key: _kAccessExpiry);
    if (expiry == null) return false;
    return DateTime.parse(expiry).isAfter(DateTime.now());
  }

  Future<bool> isRefreshTokenValid() async {
    final expiry = await _storage.read(key: _kRefreshExpiry);
    if (expiry == null) return false;
    return DateTime.parse(expiry).isAfter(DateTime.now());
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kAccessExpiry),
      _storage.delete(key: _kRefreshExpiry),
    ]);
  }

  Future<bool> hasStoredSession() async {
    final token = await _storage.read(key: _kRefreshToken);
    return token != null;
  }
}

final tokenService = TokenService();

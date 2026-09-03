import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

// Flutter never touches the database directly.
// All calls go through the Node/Express backend at [ApiConfig.baseUrl].
class ApiConfig {
  ApiConfig._();

  static const int _port = 3000;

  /// Full origin of the hosted API, e.g.
  /// `--dart-define=API_BASE_URL=https://wedpilot-api.onrender.com`.
  ///
  /// This is the only way a release build can reach a hosted backend, and it
  /// has to be https: Android blocks cleartext HTTP by default from API 28,
  /// and a browser refuses http calls made from an https page as mixed
  /// content. Takes precedence over [_host] when both are set.
  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Set via `flutter run --dart-define=API_HOST=192.168.1.20` when testing
  // on a physical device, since 'localhost' on the device refers to the
  // device itself. Find your machine's LAN IP with `ipconfig` (Windows).
  static const String _host = String.fromEnvironment('API_HOST', defaultValue: '');

  /// Whether this build carries an explicit backend address. False only in a
  /// debug build relying on the localhost defaults below.
  static bool get isExplicitlyConfigured =>
      _baseUrlOverride.isNotEmpty || _host.isNotEmpty;

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      // Trailing slash would produce '//api/...' once Dio joins the path.
      return _baseUrlOverride.endsWith('/')
          ? _baseUrlOverride.substring(0, _baseUrlOverride.length - 1)
          : _baseUrlOverride;
    }
    if (_host.isNotEmpty) return 'http://$_host:$_port';

    // A release artifact with neither define set can only ever talk to
    // localhost, which on a user's phone is the phone itself — every request
    // fails with a connection error that looks like a server outage. Failing
    // loudly at startup makes it a build problem caught on first launch
    // rather than a mystery bug reported from the field.
    if (kReleaseMode) {
      throw StateError(
        'No backend address compiled into this release build. Rebuild with '
        '--dart-define=API_BASE_URL=https://your-api-host (see README).',
      );
    }

    if (kIsWeb) return 'http://localhost:$_port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port'; // Android emulator → host localhost
    return 'http://localhost:$_port'; // iOS simulator, desktop
  }
}

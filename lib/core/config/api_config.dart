import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

// Flutter never touches the database directly.
// All calls go through the Node/Express backend at [ApiConfig.baseUrl].
class ApiConfig {
  ApiConfig._();

  static const int _port = 3000;

  // Set via `flutter run --dart-define=API_HOST=192.168.1.20` when testing
  // on a physical device, since 'localhost' on the device refers to the
  // device itself. Find your machine's LAN IP with `ipconfig` (Windows).
  static const String _host = String.fromEnvironment('API_HOST', defaultValue: '');

  static String get baseUrl {
    if (_host.isNotEmpty) return 'http://$_host:$_port';
    if (kIsWeb) return 'http://localhost:$_port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port'; // Android emulator → host localhost
    return 'http://localhost:$_port'; // iOS simulator, desktop
  }
}

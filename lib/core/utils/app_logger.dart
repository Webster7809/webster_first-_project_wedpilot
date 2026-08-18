import 'package:flutter/foundation.dart';

/// Diagnostic logging that is safe to leave in shipped code.
///
/// Both `print` and `debugPrint` stay active in a Flutter release build — a
/// bare `print(...)` in a catch block writes the caught exception straight to
/// logcat, where any app holding READ_LOGS, and anyone with `adb` and the
/// handset, can read it. The exception text in this app routinely carries the
/// thing that failed: a Dio error stringifies its request URL and headers,
/// which on an authenticated call is the bearer token.
///
/// So release builds drop console output entirely and hand the record to
/// [onError] instead, which is where a crash reporter (Sentry, Crashlytics)
/// gets attached without revisiting a single call site. Until one is wired
/// up, a release-build failure is recorded nowhere — which is the same
/// diagnostic position the app was already in, minus the token leak.
class AppLogger {
  AppLogger._();

  /// Reporting sink for release builds. Assign once during startup, e.g.
  /// `AppLogger.onError = (m, e, s) => Sentry.captureException(e, stackTrace: s);`
  static void Function(String message, Object? error, StackTrace? stackTrace)? onError;

  /// A non-fatal failure the app recovered from. [message] should name the
  /// operation, not restate the exception — the exception is passed separately
  /// so a reporter can group by type.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error == null ? '' : ': $error'}');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
    onError?.call(message, error, stackTrace);
  }

  /// Something unexpected that is not yet a failure. Debug-only by design:
  /// warnings are for the developer at the keyboard, and forwarding them to a
  /// crash reporter is how reporting quotas get burned on noise.
  static void warn(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  /// Development tracing. Compiled out of release builds entirely — the
  /// `kDebugMode` constant lets the Dart compiler drop both the call and the
  /// string interpolation that built its argument.
  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }
}

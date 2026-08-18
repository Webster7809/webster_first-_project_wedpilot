import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../config/api_config.dart';

// Every `*ApiService` funnels its DioException handling through here. Before
// this existed the same four-line `_extractError` was copy-pasted into 9
// services, and its fallback returned "Could not reach the server" for *any*
// failure that didn't carry a JSON `error` field — so a dead backend, a 500
// with an empty body, a timeout and an expired session all produced the same
// sentence. That cost a real debugging session: login failed with "could not
// reach the server" and the only way to learn the backend simply wasn't
// running was to go check the port by hand.

/// A user-facing sentence describing why [e] failed, naming the actual cause
/// rather than assuming the network is at fault.
String describeDioError(DioException e) {
  // A backend that answered at all is the most useful source of truth: our
  // Express error handler puts a human-readable sentence in `error`.
  final data = e.response?.data;
  if (data is Map && data['error'] is String) return data['error'] as String;

  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return _unreachable();

    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The server took too long to respond. Please try again.';

    case DioExceptionType.badCertificate:
      return 'The server’s security certificate could not be verified.';

    case DioExceptionType.cancel:
      return 'That request was cancelled.';

    // The server responded, just not with a body we could read — fall back to
    // what the status code alone tells us.
    case DioExceptionType.badResponse:
      return _fromStatus(e.response?.statusCode);

    // Dio reports anything it can't classify as `unknown`, including the
    // SocketException a refused connection raises on Android. Matched by name
    // rather than type because `dart:io` can't be imported on web, and this
    // file compiles for both targets.
    case DioExceptionType.unknown:
      if (e.error is Exception &&
          e.error.toString().contains('SocketException')) {
        return _unreachable();
      }
      return 'Something went wrong. Please try again.';
  }
}

/// The same, for a `catch` block that may see errors other than Dio's —
/// a [StateError] from [ApiConfig] on a misconfigured release build, or a
/// parse failure on an unexpected payload. Neither is a network problem, and
/// labelling them as one hides a build bug behind a connectivity message.
String describeError(Object error) {
  if (error is DioException) return describeDioError(error);

  // ApiConfig throws this when a release build carries no backend address.
  // Surfacing it verbatim is deliberate: it names the missing dart-define.
  if (error is StateError) return error.message;

  return 'Something went wrong. Please try again.';
}

String _fromStatus(int? status) {
  switch (status) {
    case 400:
      return 'That request wasn’t valid. Please check the details and try again.';
    // authenticated_dio already tried a token refresh and retried once, so a
    // 401 reaching here means the session really is unrecoverable.
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return 'You don’t have permission to do that.';
    case 404:
      return 'We couldn’t find that. It may have been removed.';
    case 409:
      return 'That conflicts with something that already exists.';
    case 413:
      return 'That file is too large to upload.';
    case 429:
      return 'Too many attempts. Please wait a moment and try again.';
    case null:
      return 'Something went wrong. Please try again.';
    default:
      if (status >= 500) {
        return 'The server ran into a problem ($status). Please try again.';
      }
      return 'Something went wrong ($status). Please try again.';
  }
}

String _unreachable() {
  // In debug the address is the single most useful fact — it distinguishes
  // "backend isn't running" from "this build is pointed at the wrong host"
  // (10.0.2.2 on a physical device, a stale LAN IP, a missing adb reverse).
  // Safe to read here: ApiConfig.baseUrl only throws in release builds.
  if (kDebugMode) {
    return 'Could not reach the server at ${ApiConfig.baseUrl} — '
        'check that the backend is running.';
  }
  return 'Could not reach the server. Please check your connection and try again.';
}

import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wed_plan_pilot/core/config/api_config.dart';
import 'package:wed_plan_pilot/core/services/api_error.dart';

/// Regression cover for the message every `*ApiService` shows when a call
/// fails. The bug these guard against: the old `_extractError` returned
/// "Could not reach the server" for *any* failure without a JSON `error`
/// field, so a dead backend, an empty 500, a timeout and an expired session
/// were indistinguishable in the UI — a login failure gave no hint that the
/// backend simply wasn't running.

final _request = RequestOptions(path: '/api/auth/login');

DioException _err(
  DioExceptionType type, {
  int? status,
  Object? data,
  Object? error,
}) {
  return DioException(
    requestOptions: _request,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response<Object?>(
            requestOptions: _request,
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  group('describeDioError — server spoke', () {
    test('a JSON error field wins, whatever the status code', () {
      final message = describeDioError(_err(
        DioExceptionType.badResponse,
        status: 401,
        data: {'error': 'No account found. Please create an account first.'},
      ));
      expect(message, 'No account found. Please create an account first.');
    });

    test('an error field on a 500 still wins over the status fallback', () {
      final message = describeDioError(_err(
        DioExceptionType.badResponse,
        status: 500,
        data: {'error': 'Something went wrong. Please try again.'},
      ));
      expect(message, 'Something went wrong. Please try again.');
    });
  });

  group('describeDioError — server answered without a usable body', () {
    test('an empty 500 reads as a server fault, not a network one', () {
      final message =
          describeDioError(_err(DioExceptionType.badResponse, status: 500));
      expect(message, contains('500'));
      expect(message, contains('server ran into a problem'));
      // The whole point: this must no longer claim the server is unreachable.
      expect(message, isNot(contains('Could not reach')));
    });

    test('a 503 behind a proxy returning HTML is still a server fault', () {
      final message = describeDioError(_err(
        DioExceptionType.badResponse,
        status: 503,
        data: '<html><body>502 Bad Gateway</body></html>',
      ));
      expect(message, contains('503'));
      expect(message, isNot(contains('Could not reach')));
    });

    test('401 reads as an expired session', () {
      final message =
          describeDioError(_err(DioExceptionType.badResponse, status: 401));
      expect(message, contains('session has expired'));
    });

    test('403 reads as a permission problem', () {
      final message =
          describeDioError(_err(DioExceptionType.badResponse, status: 403));
      expect(message, contains('permission'));
    });

    test('404 reads as a missing record', () {
      final message =
          describeDioError(_err(DioExceptionType.badResponse, status: 404));
      expect(message, contains('find that'));
    });

    test('429 reads as rate limiting', () {
      final message =
          describeDioError(_err(DioExceptionType.badResponse, status: 429));
      expect(message, contains('Too many attempts'));
    });
  });

  group('describeDioError — never reached the server', () {
    test('connectionError names the address it tried, in debug', () {
      final message = describeDioError(_err(DioExceptionType.connectionError));
      expect(message, contains('Could not reach the server'));
      // The fact that would have short-circuited a real debugging session.
      expect(message, contains(ApiConfig.baseUrl));
      expect(message, contains('backend is running'));
    });

    test('connectionTimeout is treated as unreachable', () {
      final message = describeDioError(_err(DioExceptionType.connectionTimeout));
      expect(message, contains('Could not reach the server'));
    });

    test('a refused connection surfaced as unknown is still unreachable', () {
      final message = describeDioError(_err(
        DioExceptionType.unknown,
        error: const SocketException('Connection refused'),
      ));
      expect(message, contains('Could not reach the server'));
    });
  });

  group('describeDioError — slow, not absent', () {
    test('receiveTimeout is distinguished from unreachable', () {
      final message = describeDioError(_err(DioExceptionType.receiveTimeout));
      expect(message, contains('took too long'));
      expect(message, isNot(contains('Could not reach')));
    });

    test('sendTimeout is distinguished from unreachable', () {
      final message = describeDioError(_err(DioExceptionType.sendTimeout));
      expect(message, contains('took too long'));
    });
  });

  group('describeError — non-Dio failures', () {
    test('a Dio error is delegated unchanged', () {
      final e = _err(DioExceptionType.badResponse, status: 404);
      expect(describeError(e), describeDioError(e));
    });

    test('ApiConfig\'s misconfigured-build StateError is surfaced verbatim', () {
      // ApiConfig throws this when a release build carries no backend address.
      // Reporting it as a connection problem would hide a build bug.
      const detail = 'No backend address compiled into this release build.';
      expect(describeError(StateError(detail)), detail);
    });

    test('an unexpected error does not blame the network', () {
      final message = describeError(FormatException('bad payload'));
      expect(message, 'Something went wrong. Please try again.');
      expect(message, isNot(contains('Could not reach')));
    });
  });
}

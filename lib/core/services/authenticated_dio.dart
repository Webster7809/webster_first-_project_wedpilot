import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'session_manager.dart';

const _kRetriedFlag = 'wedpilot_retried_after_refresh';

/// A [Dio] instance wired to transparently refresh the access token on a 401
/// and retry the request once, instead of surfacing "session expired" for
/// every action a couple takes once the (deliberately short-lived, 1h)
/// access token runs out. Every authenticated `*ApiService` should build its
/// client through this rather than constructing its own `Dio(BaseOptions(...))`
/// — that used to be duplicated across 9 files with no shared auth recovery
/// at all.
Dio buildApiDio() {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final response = error.response;
        final request = error.requestOptions;
        final hadAuthHeader = request.headers['Authorization'] != null;
        final alreadyRetried = request.extra[_kRetriedFlag] == true;

        // Only an authenticated call that hasn't already been through one
        // retry cycle is worth attempting to recover — retrying again after
        // a fresh token still 401s would just loop.
        if (response?.statusCode != 401 || !hadAuthHeader || alreadyRetried) {
          return handler.next(error);
        }

        final newToken = await sessionManager.refreshAccessToken();
        if (newToken == null) {
          // Refresh itself failed — sessionManager already fired
          // onSessionExpired, which routes the app back to login. The
          // original 401 still propagates so this call site's existing
          // error handling (every *ApiService already has one) runs too.
          return handler.next(error);
        }

        try {
          final retryOptions = request.copyWith(
            extra: {...request.extra, _kRetriedFlag: true},
            headers: {...request.headers, 'Authorization': 'Bearer $newToken'},
          );
          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ),
  );

  return dio;
}

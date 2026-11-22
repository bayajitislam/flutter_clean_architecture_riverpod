import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/core/services/app_logger.dart';

/// Logs the method, path, and status code.
///
/// Headers, query parameters, and bodies are omitted so passwords and the
/// `Authorization` header cannot reach the console.
class RedactingLogInterceptor extends Interceptor {
  const RedactingLogInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.instance.api('${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final code = response.statusCode;
    AppLogger.instance.api(
      '${response.requestOptions.method} ${response.requestOptions.uri.path} -> $code',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.instance.error(
      '${err.requestOptions.method} ${err.requestOptions.uri.path} failed',
    );
    handler.next(err);
  }
}

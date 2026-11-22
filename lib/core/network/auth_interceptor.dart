import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/core/storage/token_storage.dart';

/// Adds the stored bearer token to outgoing requests.
///
/// The token value is never written to logs.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await _tokenStorage.readSession();
    final token = session?.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

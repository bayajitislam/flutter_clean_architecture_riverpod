import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/network/auth_interceptor.dart';
import 'package:flutter_clean_architecture_riverpod/core/network/redacting_log_interceptor.dart';
import 'package:flutter_clean_architecture_riverpod/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform secure storage. Override this in tests.
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Session token store.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage(ref.watch(flutterSecureStorageProvider));
});

/// The single Dio client for the app.
///
/// Features must use this provider instead of constructing another [Dio].
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref.watch(tokenStorageProvider)));
  if (kDebugMode) {
    dio.interceptors.add(const RedactingLogInterceptor());
  }
  ref.onDispose(dio.close);
  return dio;
});

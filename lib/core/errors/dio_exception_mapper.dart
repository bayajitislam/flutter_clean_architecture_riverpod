import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';

/// Maps a [DioException] to a [Failure] without copying headers or bodies.
///
/// Response bodies and the `Authorization` header are never placed on the
/// failure message.
Failure mapDioException(DioException error) {
  final statusCode = error.response?.statusCode;
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(
      'Check your connection and try again.',
    ),
    DioExceptionType.badResponse when statusCode == 401 || statusCode == 403 =>
      const UnauthorizedFailure(),
    DioExceptionType.badResponse when statusCode == 400 || statusCode == 422 =>
      const ValidationFailure('The request was rejected.'),
    DioExceptionType.cancel => const NetworkFailure(
      'The request was cancelled.',
    ),
    _ => const UnknownFailure(),
  };
}

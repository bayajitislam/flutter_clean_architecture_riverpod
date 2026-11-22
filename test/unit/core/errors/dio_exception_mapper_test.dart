import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/dio_exception_mapper.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapDioException', () {
    test('maps HTTP 401 to unauthorized without copying the body', () {
      final failure = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/auth/sign-in'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/auth/sign-in'),
            statusCode: 401,
            data: const <String, String>{'token': 'secret-token'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message.contains('secret-token'), isFalse);
    });

    test('maps a connection error to a network failure', () {
      final failure = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/auth/sign-in'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(failure, isA<NetworkFailure>());
    });
  });
}

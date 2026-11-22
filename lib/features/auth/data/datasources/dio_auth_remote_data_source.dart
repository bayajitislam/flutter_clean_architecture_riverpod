import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_exception.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/models/auth_session_model.dart';

/// `POST /auth/sign-in` through the shared Dio client.
class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  const DioAuthRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<AuthSessionModel> signIn({
    required String email,
    required String password,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Object?>(
      '/auth/sign-in',
      data: <String, String>{'email': email, 'password': password},
      cancelToken: cancelToken,
    );
    final body = response.data;
    if (body is! Map<Object?, Object?>) {
      throw const AuthRemoteException(
        'The server returned an unexpected response.',
      );
    }
    return AuthSessionModel.fromJson(Map<String, dynamic>.from(body));
  }
}

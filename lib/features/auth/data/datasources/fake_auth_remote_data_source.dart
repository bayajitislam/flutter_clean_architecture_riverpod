import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_exception.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/models/auth_session_model.dart';

/// Accepts any non-empty email that contains `@`.
///
/// Used when `API_BASE_URL` is empty so the template runs without a backend.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  const FakeAuthRemoteDataSource();

  @override
  Future<AuthSessionModel> signIn({
    required String email,
    required String password,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const AuthRemoteException('The request was cancelled.');
    }
    final trimmed = email.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      throw const AuthRemoteException('Email and password are required.');
    }
    if (!trimmed.contains('@')) {
      throw const AuthRemoteException('Enter a valid email.');
    }
    return AuthSessionModel(token: 'fake-token', email: trimmed);
  }
}

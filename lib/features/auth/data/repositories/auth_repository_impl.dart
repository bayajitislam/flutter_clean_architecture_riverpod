import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/dio_exception_mapper.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/core/services/app_logger.dart';
import 'package:flutter_clean_architecture_riverpod/core/storage/token_storage.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_exception.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/credentials.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remote, required this.tokenStorage});

  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  @override
  Future<Result<AuthSession>> signIn(Credentials credentials) async {
    try {
      final model = await remote.signIn(
        email: credentials.email,
        password: credentials.password,
      );
      await tokenStorage.writeSession(token: model.token, email: model.email);
      return Result.success(model.toEntity());
    } on AuthRemoteException catch (error) {
      return Result.failure(ValidationFailure(error.message));
    } on DioException catch (error) {
      return Result.failure(mapDioException(error));
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Sign-in failed (${error.runtimeType})',
        null,
        stackTrace,
      );
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<bool>> signOut() async {
    try {
      await tokenStorage.clear();
      return const Result.success(true);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Sign-out failed (${error.runtimeType})',
        null,
        stackTrace,
      );
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<AuthSession?>> readSession() async {
    try {
      final stored = await tokenStorage.readSession();
      if (stored == null) {
        return const Result.success(null);
      }
      return Result.success(
        AuthSession(token: stored.token, email: stored.email),
      );
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Reading the session failed (${error.runtimeType})',
        null,
        stackTrace,
      );
      return const Result.failure(UnknownFailure());
    }
  }
}

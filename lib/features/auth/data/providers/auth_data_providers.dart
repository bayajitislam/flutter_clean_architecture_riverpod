import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/network/dio_provider.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/dio_auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chooses the fake source until `API_BASE_URL` is set.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final env = ref.watch(appEnvProvider);
  if (!env.hasApi) {
    return const FakeAuthRemoteDataSource();
  }
  return DioAuthRemoteDataSource(ref.watch(dioProvider));
});

/// Auth repository used by the auth use cases.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

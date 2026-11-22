import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/data/models/auth_session_model.dart';

/// Remote sign-in API.
///
/// Pass [cancelToken] to cancel the in-flight Dio call. Sources that do not
/// use the network ignore it.
abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> signIn({
    required String email,
    required String password,
    CancelToken? cancelToken,
  });
}

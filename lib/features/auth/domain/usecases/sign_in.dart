import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/credentials.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/repositories/auth_repository.dart';

/// Signs the user in and stores the returned session.
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call(Credentials credentials) {
    return _repository.signIn(credentials);
  }
}

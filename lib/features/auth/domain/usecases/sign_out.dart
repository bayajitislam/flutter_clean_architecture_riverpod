import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/repositories/auth_repository.dart';

/// Clears the stored session.
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<bool>> call() => _repository.signOut();
}

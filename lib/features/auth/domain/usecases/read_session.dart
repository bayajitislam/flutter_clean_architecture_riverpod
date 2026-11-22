import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/repositories/auth_repository.dart';

/// Restores the session saved on this device.
class ReadSession {
  const ReadSession(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession?>> call() => _repository.readSession();
}

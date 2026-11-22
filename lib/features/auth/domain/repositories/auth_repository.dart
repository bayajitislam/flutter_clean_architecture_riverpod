import 'package:flutter_clean_architecture_riverpod/core/errors/result.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/credentials.dart';

/// Auth data access used by use cases.
///
/// Implementations live in the data layer. Presentation must not implement
/// this type or call a data source directly.
abstract class AuthRepository {
  Future<Result<AuthSession>> signIn(Credentials credentials);

  Future<Result<bool>> signOut();

  /// Returns the stored session, or `null` when the user is signed out.
  Future<Result<AuthSession?>> readSession();
}

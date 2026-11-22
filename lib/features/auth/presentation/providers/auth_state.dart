import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// Whether a stored session has been restored.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Immutable auth screen state.
///
/// Freezed supplies equality and `copyWith`. This state is not serialized.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    AuthSession? session,
    Failure? failure,
    @Default(false) bool isSubmitting,
  }) = _AuthState;
}

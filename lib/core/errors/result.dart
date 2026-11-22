import 'package:flutter_clean_architecture_riverpod/core/errors/failure.dart';

/// The outcome of a repository or use case call.
///
/// Repositories return this instead of throwing for expected failures.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;

  const factory Result.failure(Failure failure) = ErrorResult<T>;

  /// Branches on the two outcomes without exposing the subtype.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      ErrorResult<T>(:final failure) => onFailure(failure),
    };
  }
}

/// A completed call that produced [data].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

/// A completed call that produced a [Failure].
final class ErrorResult<T> extends Result<T> {
  const ErrorResult(this.failure);

  final Failure failure;
}

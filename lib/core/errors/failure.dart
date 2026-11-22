/// A user-facing failure that repositories return inside [Result].
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// The device could not complete a network call.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// The server rejected the call because the session is missing or expired.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sign in again.']);
}

/// The input or request payload was rejected.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// A failure that does not fit a more specific type.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'The request failed.']);
}

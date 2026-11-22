# Error handling

Expected failures are values. `Result<T>` is either `Success` or `ErrorResult`.

- `NetworkFailure` for timeouts, connectivity, and cancellation.
- `UnauthorizedFailure` for HTTP 401 and 403.
- `ValidationFailure` for rejected input.
- `UnknownFailure` for everything else, with a generic message.
- Repositories catch data-source exceptions and return a `Result`.
- Screens branch with `result.fold` or read `AuthState.failure`.
- Log the failure category, not the request body. `mapDioException` drops headers and response bodies so a token cannot leak into a message.

Startup errors go through `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded` in `lib/main.dart`.

## Do not

- Throw from a repository for an expected API error.
- Catch an exception and ignore it.
- Put `DioException` in a widget's state.

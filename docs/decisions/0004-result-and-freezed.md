# Result at the boundary, Freezed for models

## Context

API calls fail in ways the UI must show. Models need equality and `copyWith`. Not every type needs a generator.

## Decision

Repositories return a handwritten `Result<T>` (`Success` or `ErrorResult`). Failures are `NetworkFailure`, `UnauthorizedFailure`, `ValidationFailure`, and `UnknownFailure`. Freezed is used for API models and for immutable state such as `AuthState`. `Result`, entities, and services stay ordinary Dart.

## Alternatives considered

- Throwing exceptions through the use case. Call sites forget to catch them, and a Dio error can leak a body into the UI.
- Freezed for `Result` as well. The sealed type is short and does not need a build step.
- Hand-written JSON for every model. It drifts from the generator the feature command already runs.

## Consequences

Screens fold a result into loading, success, empty, or failure. Generated `*.freezed.dart` and `*.g.dart` files are committed. A model change is not done until `build_runner` has been run.

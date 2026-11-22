# Code review

Review for behavior first, then for architecture.

- Domain files do not import Flutter or Dio.
- Screens do not construct `Dio` or read secure storage directly.
- New network calls use `dioProvider` and `mapDioException`.
- Secrets, tokens, and passwords are not logged or committed.
- State changes go through a Riverpod notifier.
- The change does not edit unrelated features.
- Tests cover the new behavior and the relevant failure.
- `flutter analyze` and `flutter test` were run.

A rename must go through `dart run tool/cli.dart rename`. Do not approve a hand-edited bundle id that leaves Gradle, Xcode, and `tool/project_identity.yaml` out of sync.

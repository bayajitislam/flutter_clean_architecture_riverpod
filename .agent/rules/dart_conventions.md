# Dart conventions

- Name files `lower_snake_case.dart` and types `UpperCamelCase`.
- Use `lowerCamelCase` for members and `SCREAMING_CAPS` is not used for constants. Prefer `lowerCamelCase` on `static const`.
- Prefer `final` locals and `const` constructors.
- Use package imports (`package:<pubspec name>/...`) inside `lib` and `test`. The rename CLI rewrites that prefix.
- Keep one public type per file unless the types are only used together, as `Result` and `Success` are.
- Do not add a library prefix or a barrel file unless a feature has a stable public surface.

## Do

```dart
final session = await repository.readSession();
```

## Do not

```dart
var session = await repository.readSession();
import '../domain/entities/auth_session.dart';
```

Relative imports inside `lib` fail `always_use_package_imports` and break the rename tool's import update.

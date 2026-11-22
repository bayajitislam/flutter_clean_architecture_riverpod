# Code generation

Freezed and json_serializable are part of this template. Generated files are committed so the app compiles before a developer runs the generator again.

Generate after changing an annotated class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Never edit `*.freezed.dart` or `*.g.dart` by hand. Change the source class and run the command again.

## Why Freezed

Freezed writes `copyWith`, value equality, and `toString` for immutable data. With json_serializable it also writes `fromJson` and `toJson`. That removes handwritten equality bugs in models and screen state.

## When to use `@freezed`

Use it for:

- API response and request models.
- Immutable domain models when value equality matters.
- Screen state with several fields, such as `AuthState`.
- Union types: loading, success, and failure, or other sealed states.
- Immutable configuration objects when copy and equality are useful.

Use `@freezed` with union factories when a value is one of several shapes. This snippet is a pattern, not a type shipped in the template:

```dart
@freezed
abstract class LoadState with _$LoadState {
  const factory LoadState.loading() = _Loading;
  const factory LoadState.ready(List<Item> items) = _Ready;
  const factory LoadState.failed(String message) = _Failed;
}
```

## When a normal class is enough

Do not use Freezed for:

- Simple enums.
- Constants.
- Services and repositories.
- Utility classes.
- A class that does not need generated equality, `copyWith`, unions, or JSON.

`Result` stays a handwritten sealed class because callers use `fold` and the type is not serialized.

## Equality, copyWith, and JSON

Two Freezed values are equal when every field is equal. Fields that are ordinary Dart objects use that object's `==`.

`copyWith` returns a new value and leaves omitted fields as they are. Passing `null` to a nullable field clears it.

JSON models add a `fromJson` factory and a `toJson` method. Add both part files:

```dart
part 'item_model.freezed.dart';
part 'item_model.g.dart';
```

State that contains a `Failure` or another non-JSON type uses only the Freezed part file. Do not add `fromJson` to that class.

Map a model to an entity in the repository. Do not pass the generated model into a widget.

## Project conventions

- Annotate with `@freezed` on an `abstract class` that mixes in the generated class.
- Keep one Freezed type per file, next to its parts.
- `analysis_options.yaml` excludes generated files.
- The feature generator writes one Freezed model and runs this command unless `--skip-codegen` or `--dry-run` is set.

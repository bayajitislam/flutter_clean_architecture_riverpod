# Dependencies

Each direct dependency has one job. Do not add a second package for that job.

| Package | Why it is here | License |
| --- | --- | --- |
| `flutter_riverpod` | State and dependency injection. Notifiers own screen state. | MIT |
| `go_router` | Declarative routes and the auth redirect. | BSD-3-Clause |
| `dio` | The only HTTP client, behind `dioProvider`. | MIT |
| `freezed_annotation`, `freezed` | Immutable models and state. Generated files are committed. | MIT |
| `json_annotation`, `json_serializable` | JSON mapping for API models. | BSD-3-Clause |
| `flutter_secure_storage` | Session token and email. | BSD-3-Clause |
| `shared_preferences` | Theme mode and other non-sensitive settings. | BSD-3-Clause |
| `flutter_devlog` | Logging, only through `AppLogger`. | MIT |
| `remixicon` | Remix glyphs used by `AppIcons`. Flutter's own `Icons` stay available on that class. | MIT |
| `flutter_lints` | Analyzer rules. | BSD-3-Clause |
| `args` | CLI parsing in `tool/`. | BSD-3-Clause |
| `yaml` | Reads `tool/project_identity.yaml` and pubspec checks. | MIT |
| `analyzer` | Architecture import checks in `validate`. | BSD-3-Clause |
| `build_runner` | Runs Freezed and JSON generation. | BSD-3-Clause |
| `mocktail` | Test doubles. | MIT |

Flutter and Dart use the Flutter SDK license.

`cupertino_icons` was removed. The starter does not ship a second icon font for Cupertino.

## Not installed

Firebase, Drift, RevenueCat, localization, and an offline cache are intentionally absent. Add one when a product needs it. An optional package does not belong in the template "just in case."

## Overlap

Riverpod is the only state library. GoRouter is the only router. Dio is the only HTTP client. `AppLogger` is the only logger. `AppIcons` is the only icon entry point.

## Before adding a package

1. Name the problem the current code cannot solve.
2. Check the license against the license this repository eventually adopts.
3. Add it to `requiredDependencies` in `tool/src/validate_project.dart` only when every generated project must have it.
4. Mention it in this file and in the README stack list.

License names above describe the packages at the versions in `pubspec.lock`. Read the license file inside each package before you redistribute it. The Remix icon artwork has its own upstream terms; the `remixicon` package distributes it under the license in that package.

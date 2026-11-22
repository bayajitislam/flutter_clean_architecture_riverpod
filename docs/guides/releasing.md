# Releasing

No public release has been published. Do not tag a release or change `pubspec.yaml` unless the maintainers ask for it.

## Version numbers

This project uses semantic versioning.

- **MAJOR** when a generated app or a public CLI flag must change to keep working.
- **MINOR** for a backward-compatible feature.
- **PATCH** for a backward-compatible fix.

`pubspec.yaml` uses Flutter's `version: x.y.z+build`. The `+build` number is the template build, not a store build of a product app. People who run `awesome create` replace the identity. They choose their own store version after that.

## Changelog

Add every user-visible change under `## [Unreleased]` in `CHANGELOG.md` before it is released. Group entries as Added, Changed, Fixed, or Removed.

When the maintainers publish a version:

1. Move the `Unreleased` notes under `## [x.y.z] - YYYY-MM-DD`.
2. Set `version` in `pubspec.yaml` to that number.
3. Summarize breaking changes and the migration steps in the same section.
4. Tag the commit after the checks in CI are green.

## Before a release

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run :awesome validate
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
flutter build web
```

Review dependency updates with `flutter pub outdated`. A major upgrade of Riverpod, GoRouter, Dio, or Freezed needs a changelog note and a test run. Do not upgrade a package only because a newer version exists.

## Breaking changes

Call a change breaking when it changes a CLI flag, a generated file path, a provider name that apps override, or a theme token name. Describe the old call and the new call in the changelog. Keep the old behavior for one minor release when that can be done without two architectures.

## Dependency updates

Update one group at a time. Read the package changelog. Confirm the license is still compatible with the license this repository uses once the maintainers choose one. Run the checks above. Commit `pubspec.lock`.

# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and this changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

The version in `pubspec.yaml` is the template version.

## [0.1.0] - 2026-11-22

### Added

- MIT license (Copyright (c) 2026 Bayajit Islam).
- `fcar` CLI: `create`, `init`, `rename`, `feature`, and `validate`.
- Feature-first clean architecture with Riverpod, GoRouter, Dio, Freezed, and theming.
- Auth flow with a fake source for local development and a Dio source when an API URL is set.
- Showcase feature for separate mobile, tablet, and desktop layouts.
- Architecture overview, dependency notes, extension guide, release guide, and ADRs.
- CI for format, analyze, tests, validate, code-generation diff, and web build.
- Dependabot for pub and GitHub Actions.
- Auth redirect widget tests and README screenshots (light and dark).
- Accessibility labels on shared buttons and fields.
- Decision record for `material_ui` and a "why not Bloc / Provider / GetX" section for Riverpod.

### Changed

- Project identity is Flutter Clean Architecture Riverpod (`flutter_clean_architecture_riverpod`, `com.flutter.cleanarchitectureriverpod`).
- CLI executable renamed from `awesome` to `fcar`.
- Material imports use `package:material_ui/material_ui.dart`.
- CI pins Flutter `3.44.8` and only diffs generated Freezed/JSON files after `build_runner`.
- Login and home copy use shared string constants; spacing uses `AppSpacing`.

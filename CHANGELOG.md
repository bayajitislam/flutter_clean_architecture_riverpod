# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and this changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

The version in `pubspec.yaml` is the template version. No public release has been published from this repository. Do not treat a changelog heading as a published release until the maintainers say so.

## [Unreleased]

### Added

- MIT license (Copyright (c) 2026 Bayajit Islam).
- `create` writes an independent application with its own README and docs.
- `init` rebrands a GitHub template checkout, with a snapshot under `.awesome-backup/` and a no-op second run.
- Showcase is optional. Sample sign-in can be removed with `--no-auth`.
- Architecture overview, dependency notes, extension guide, release guide, and architecture decision records.
- CI checks for project validation, committed code generation, and the web build.
- `awesome create` skips local environment files, signing files, machine SDK paths, and crash logs.

### Changed

- Project identity is now Flutter Clean Architecture Riverpod (`flutter_clean_architecture_riverpod`, `com.flutter.cleanarchitectureriverpod`).
- `cupertino_icons` was replaced by Remix Icon through `AppIcons`, which also exposes Flutter's built-in icons.

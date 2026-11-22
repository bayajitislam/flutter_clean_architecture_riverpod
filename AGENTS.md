<!-- identity:start -->
# Flutter Clean Architecture Riverpod

- Package name: `flutter_clean_architecture_riverpod`
- Display name: Flutter Clean Architecture Riverpod
- Bundle id: `com.flutter.cleanarchitectureriverpod`
<!-- identity:end -->

# Flutter project development rules

This is a production-oriented Flutter application built with feature-first clean architecture. Read the existing structure before editing it. The long-form rules live in `.agent/rules/` and the task workflows live in `.agent/workflows/`.

## Technology stack

- Flutter and Dart
- Riverpod for state and dependency injection
- GoRouter for navigation
- Dio for HTTP, through the shared client in `lib/core/network`
- Freezed and json_serializable for API models and suitable immutable state
- Flutter Secure Storage for tokens
- Shared preferences for non-sensitive settings
- flutter_devlog for logging, through `AppLogger`
- Repository contracts in the domain layer

Do not add a second state manager, router, or HTTP client. Do not add a package that the task does not need. Freezed rules are in `.agent/rules/code_generation.md`.

## Architecture

- Keep each feature under `lib/features/<feature>/{data,domain,presentation}`.
- Domain code must not import Flutter, Dio, or a data-source implementation.
- Presentation calls use cases. Screens and widgets do not call Dio or import a feature `data` folder.
- Wire Dio and repository implementations in `data/providers`. A presentation provider may import that file for the same feature.
- Data sources do not import widgets.
- A feature must not import another feature's `data` or `domain` folder.
- Put cross-feature widgets and types in `lib/shared` and infrastructure in `lib/core`.
- Add a use case for each action a screen can take. Do not add empty layers for a screen that has no business logic.

## Environments

`AppEnv` reads `FLAVOR`, `API_BASE_URL`, and `APP_NAME` from `--dart-define-from-file`. Copy `env/dev.json.example` to `env/dev.json`. Staging and production fail at startup when `API_BASE_URL` is empty. Development may leave it empty and use the fake auth source. Do not commit `env/*.json`.

## Project CLI

From the project root:

```bash
dart run tool/awesome.dart create my_shop --output ../my_shop
dart run :awesome init my_shop
dart run :awesome rename my_app
dart run :awesome feature create products
dart run :awesome validate
```

`tool/awesome.dart` and `tool/cli.dart` run the same commands. `create` writes an independent app and does not modify this starter. `init` rebrands a GitHub template checkout in place. Do not run `init` on this starter if it should stay the template. `--dry-run` prints planned edits. Feature generation refuses to overwrite a file unless `--force` is set. Rename edits known identity fields and leaves signing, Firebase files, entitlements, and URL schemes alone. The handoff guide is `docs/guides/handoff.md`.

## State, API, and UI

- Use Riverpod `Notifier`s and `Provider`s. Do not use `setState` for session, network, or theme state.
- Do not assign `state` synchronously inside `build`. Return the initial state and start the request afterward. Generated list controllers use `RequestGate`.
- Model loading, success, and failure explicitly. Repositories return `Result<T>`.
- Use `dioProvider`. Do not construct another `Dio`.
- Keep request and response models typed. Do not hardcode URLs or secrets.
- Pass a `CancelToken` when a screen can leave before a request finishes.
- Reuse `AppButton`, `AppTextField`, `AppLoading`, `AppErrorView`, and `showAppConfirmDialog`.
- Use `Theme.of(context)`, `colorScheme`, and `textTheme`. `ContextX` exposes `colors`, `textTheme`, and `statusColors`.
- Take spacing from `AppSpacing` and corners from `AppRadius`. Do not hardcode colors or text styles.
- Take icons from `AppIcons`. Remix glyphs are the default fields. Flutter's built-in icons are the Material fields on the same class. Do not import `RemixIcons` or use `Icons` in a feature.
- Change the brand color in `AppColors.brand`. Light, dark, and system modes go through `themeModeControllerProvider`.
- Mobile, tablet, and desktop use the same theme. Do not build a second widget just to switch colors.
- Log through `AppLogger`. It wraps `flutter_devlog`. Do not call `print`, `debugPrint`, or `DevLog` from a feature.
- Choose a layout strategy in `.agent/rules/flutter_ui.md`. Share providers and use cases across mobile, tablet, and desktop.

## Security and quality

- Never commit API secrets, keystores, or `env/*.json`.
- Never log passwords, tokens, API keys, or the `Authorization` header.
- `AppLogger.debug` uses a `DEBUG` level at `LogPriority.ui`, because `flutter_devlog` has no `debug` method. `warning` calls `DevLog.warn`. Development shows every level, staging keeps warnings and errors, and production disables the logger.
- Never disable a lint or a security check to make a task pass.
- Keep functions small. Do not leave unused imports.
- Document behavior that is not obvious from the signature.

## Testing

- Unit-test use cases, repositories, and pure mappings.
- Widget-test important screens and forms.
- Run `dart format`, `flutter analyze`, the relevant `flutter test`, and `dart run :awesome validate` before calling a task done.
- After a Freezed or JSON model change, run `dart run build_runner build --delete-conflicting-outputs`. Do not hand-edit the generated files.

## Workflow

1. Inspect the surrounding feature and the matching rule in `.agent/rules/`.
2. Name the files you will change.
3. Implement with the existing patterns.
4. Format, analyze, and test.
5. Report the files changed and anything you could not verify.

## Restrictions

- Do not rewrite the architecture, delete behavior, or edit unrelated files without an explicit request.
- Do not invent API endpoints, response fields, or dependencies.
- Do not claim a task is complete when analyze or tests are failing.
- Preserve the identity markers in this file and in `README.md`. The rename CLI replaces that block.

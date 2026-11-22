# Contributing

Thanks for helping improve this starter kit. Changes should stay useful for people who generate their own apps from it, not only for one private product.

## Create an application

People who want their own app should not fork this repository and keep editing it as the starter. Use `dart run tool/awesome.dart create` or the GitHub template `init` flow in [docs/guides/handoff.md](docs/guides/handoff.md).

## Fork and clone

1. Fork the repository on the host where it lives.
2. Clone your fork and enter the directory.

```bash
git clone <your-fork-url>
cd <repository-directory>
```

3. Add the original repository as `upstream` when you want to update your fork later.

This repository does not publish a canonical remote URL in the docs. Use the URL of the repository you forked.

## What you need

- Flutter on the stable channel. The Dart SDK constraint is in `pubspec.yaml` (`sdk: ^3.12.2`).
- A working Flutter install for the platforms you touch. Android and iOS tooling are only required when you change those projects.
- No API account is required. Development runs with a fake auth source when `API_BASE_URL` is empty.

## Install and run

```bash
flutter pub get
cp env/dev.json.example env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` stays untracked. The example files contain empty placeholders. Do not put real keys in a commit.

Sign in with any valid email and a password of at least 8 characters while the fake source is in use.

## Code generation

Freezed and `json_serializable` write the `*.freezed.dart` and `*.g.dart` files. After you change a model or Freezed state class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the generated files. Do not edit them by hand. CI runs the same command and fails if the result differs from the commit.

## Checks

Run these before you open a pull request:

```bash
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run :awesome validate
```

`dart run tool/cli.dart` is the same CLI. `validate` checks layout, identity, architecture imports, env examples, and required files.

## Conventions

- Formatting and lints come from `analysis_options.yaml`.
- Features follow `lib/features/<feature>/{data,domain,presentation}`. Domain code does not import Flutter or Dio. Screens do not import a feature `data` folder or call Dio.
- State and dependency injection use Riverpod. Navigation uses GoRouter. HTTP uses the shared Dio client.
- Read colors, type, spacing, radius, and icons from the theme and `AppIcons`.
- The enforceable rules for people and coding agents are in `.agent/rules/`. The explanation of why the architecture looks this way is in `docs/architecture/overview.md`.

## Create a feature

From the repository root:

```bash
dart run :awesome feature create products --dry-run
dart run :awesome feature create products
```

The command writes data, domain, presentation, a repository test, and a screen test. The remote source throws `UnimplementedError` until a real endpoint is agreed. It does not edit the router and does not overwrite a file unless you pass `--force`.

Then register a `GoRoute` in `lib/core/routing/app_router.dart`. A presentation-only feature uses `--presentation-only`. Hand-written steps are in `.agent/workflows/new_feature.md`.

## Add a reusable widget

1. If only one feature uses it, put it in `lib/features/<feature>/presentation/widgets/`.
2. If two features use it, put it in `lib/shared/widgets/`.
3. If it is a starter-kit control, such as a button used by every screen, put it in `lib/core/widgets/`.
4. Keep the widget small. Pass the data it renders and the callbacks it needs. Do not give it a repository or a Dio client.
5. Use `AppSpacing`, `AppRadius`, `AppIcons`, and `Theme.of(context)`.
6. Add a widget test for the main interaction when the widget has behavior.
7. Give an icon-only control a tooltip, and a text label where a screen reader needs one.

More detail is in `docs/guides/extending.md`.

## Add a screen

1. Put the screen in the feature's `presentation/screens/`.
2. Call a use case through a Riverpod notifier. Keep loading, success, empty, and failure visible in that state.
3. Register the route in `lib/core/routing/app_router.dart` with a path from `RoutePaths`.
4. Start with one screen inside `ResponsiveBody` when the same design works at every width.
5. Add `screens/tablet` and `screens/desktop` only when the layout is actually different. The showcase feature is the reference. Those screens share one provider.

## Add a responsive layout

Measure width with `LayoutBuilder` and `screenSizeOf`. The default breakpoints are 600 for tablet and 1024 for desktop. Use `AdaptiveLayout` to choose a widget tree, and `AdaptiveNavigation` only when the screen needs a bottom bar, rail, or sidebar. Do not build three copies of a simple page.

## Add a CLI command

1. Add a `Command<int>` in `tool/src/` and register it from `tool/src/cli_runner.dart`.
2. Accept `--dry-run` when the command writes files. Refuse to overwrite existing files unless `--force` is set.
3. Throw `ProjectToolException` for a user mistake. Do not call `exit` inside the command.
4. Add a fixture test under `test/unit/tool` that uses a temporary directory. Do not rename or rewrite this checkout as the test.
5. Document the command in `README.md` and in this file.

## Pull request

1. Create a branch from an up-to-date default branch.
2. Keep the change focused. A widget, a feature, and a CLI command can be separate pull requests.
3. Fill in the pull request template: summary, motivation, testing, screenshots for UI, breaking changes, and docs.
4. Say `Fixes #123` when the pull request closes an issue.
5. Do not commit `env/*.json`, keystores, `local.properties`, `Generated.xcconfig`, or crash logs.

A pull request is ready when the CI checks pass, not only when the app launches.

## Conduct and security

Be respectful. `CODE_OF_CONDUCT.md` explains how to report a conduct problem. `SECURITY.md` explains how to report a vulnerability. Do not file either one as a public issue.

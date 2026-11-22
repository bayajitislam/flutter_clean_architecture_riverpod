# Extending the starter

Add the smallest piece that solves the problem. A new abstraction needs a caller that is awkward without it. Do not add a layer to make the diagram look deeper.

## Widgets

| Who uses it | Where it lives |
| --- | --- |
| One feature | `lib/features/<feature>/presentation/widgets/` |
| Two or more features | `lib/shared/widgets/` |
| A starter control, such as `AppButton` | `lib/core/widgets/` |

A widget renders and forwards events. It does not call Dio, read a repository, or import another feature's data layer. Prefer a few clear parameters over a widget that can become any screen.

Use `Theme.of(context)`, `AppSpacing`, `AppRadius`, and `AppIcons`. Light and dark mode stay in the theme. Do not fork a widget into `MyWidgetLight` and `MyWidgetDark`.

Give an icon-only button a tooltip. Add a widget test when the widget has a branch worth protecting, such as an error message or a selected state.

## Screens

A screen composes widgets and watches a provider. Loading, success, empty, and failure are fields on the state, not booleans hidden in the widget. Empty data is a success with an empty list.

Register the screen on the router. Keep the path in `RoutePaths`.

Start with one screen. `ResponsiveBody` keeps a single column readable. Add tablet and desktop files when the navigation or the arrangement is different, and keep them on the same notifier. Showcase is the example. A simple page does not need three files.

## Features

```bash
dart run :fcar feature create orders
```

Use the layers the feature needs. A page with no business rule can be presentation-only. A page that loads remote data gets an entity, a repository contract, a use case, and a data implementation that returns `Result<T>`.

The generated remote source throws `UnimplementedError`. Replace that with a real call only when the endpoint and the response shape are known. Do not invent either one.

Do not import another feature's data or domain code. If two features need the same value, move the type to `lib/shared` or pass an id through the route.

## CLI commands

Add a command class under `tool/src/`, register it in `cli_runner.dart`, and test it with a temporary directory. Support `--dry-run` for writes. Refuse to replace an existing file unless `--force` is set. User mistakes throw `ProjectToolException`.

## Themes, tests, and tooling

- Brand color: `AppColors.brand`.
- A semantic color Material does not have: a field on `AppStatusColors`.
- A test helper used by more than one test: `test/support/`.
- A validator rule: `tool/src/validate_project.dart`, plus a fixture test.

## Integrations

Firebase, a database, payments, and localization are not part of the template. Propose one in an architecture issue when several generated apps would need the same wiring. Keep the integration behind a provider so features still call a use case.

## Compatibility

Prefer adding a field or a command flag over changing the meaning of an existing one. When a change breaks a generated project, say so in the pull request and add a migration note to `CHANGELOG.md` under `Unreleased`.

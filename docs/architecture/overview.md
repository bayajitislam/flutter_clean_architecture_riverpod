# Architecture

Flutter Clean Architecture Riverpod is a feature-first starter. Each feature owns its screens, state, use cases, and, when it talks to an API, its repository and data sources. Shared infrastructure stays in `lib/core`. Widgets and types used by more than one feature stay in `lib/shared`.

```text
lib/
  main.dart              startup, logger, ProviderScope
  app.dart               MaterialApp.router, theme, title
  core/                  config, network, storage, theme, routing, widgets
  features/<feature>/
    data/                sources, models, repository implementation, providers
    domain/              entities, repository contract, use cases
    presentation/        state, screens, widgets
  shared/                cross-feature widgets, breakpoints, enums
```

A static screen can stay presentation-only. Home does. Add `data` and `domain` when there is a business rule or a remote call.

## Boundaries

```text
presentation -> domain
data -> domain
presentation -> core
data -> core
```

Domain code imports entities, repository contracts, and `Result`. It does not import Flutter or Dio.

A screen calls a use case. It does not construct Dio or import a feature `data` folder. A presentation provider in the same feature may import that feature's `data/providers` to wire the use case.

One feature does not import another feature's `data` or `domain` folder. Navigate with a route instead.

`lib/core/routing` may import feature screens and presentation providers. It does not import feature data or domain.

`dart run :awesome validate` checks these imports, including exports and relative paths.

## Repository pattern

The domain repository is an abstract contract. The data layer implements it, maps models to entities, and returns `Result<T>`. `Success` carries the value. `ErrorResult` carries a `Failure`: network, unauthorized, validation, or unknown. Use cases stay thin. They call the repository and return its result.

## Dependency injection

Riverpod providers construct the objects. `main.dart` overrides the shared preferences and the environment before `runApp`. Features do not create a second `ProviderScope`.

Auth chooses a fake source or a Dio source in `lib/features/auth/data/providers/auth_data_providers.dart` from `AppEnv.hasApi`. Widgets read providers. They do not construct repositories.

## Riverpod

Use `Notifier` and `NotifierProvider`. Do not use `setState` for session, network, or theme state. A form may use `setState` for a field error.

Do not assign `state` inside `Notifier.build` after kicking off work. Return the initial state, then start the request. Generated list controllers use `RequestGate`, which schedules the load in a microtask, ignores a duplicate call, and drops the result if the notifier is gone.

## API communication

One Dio instance lives behind `dioProvider` in `lib/core/network`. `AuthInterceptor` adds the bearer token. `RedactingLogInterceptor` logs the method, path, and status through `AppLogger`. It does not log headers or bodies.

Do not hardcode a base URL. `AppEnv` reads `FLAVOR`, `API_BASE_URL`, and `APP_NAME` from `--dart-define-from-file`. Development may leave the URL empty. Staging and production throw at startup when it is empty.

The only real auth call in the template is `POST /auth/sign-in`, and only when a URL is set. Generated remote sources throw `UnimplementedError` until an endpoint is agreed. Do not invent response fields.

## Error handling

Repositories catch failures and return `Result`. They do not throw across the boundary for an expected API error. `mapDioException` turns Dio errors into `NetworkFailure` or `UnauthorizedFailure` and drops the response body so a token cannot leak into a message. An unexpected exception becomes `UnknownFailure`. Logs record the failure type, not the payload.

## Authentication

`AuthController` starts as `AuthStatus.unknown` and restores any stored session. The router keeps the user on the splash screen until that finishes. No session leads to `/login`. A session leads to `/`. Sign-out clears secure storage.

`TokenStorage` stores the token and email. It does not store the password. The fake source accepts any valid email and a non-empty password so the UI can be tried without a backend. The repository still rejects a blank email before the source is called.

## Navigation

`GoRouter` is created in `routerProvider`. Paths live in `RoutePaths`. The redirect reads auth state. Add a `GoRoute` when a feature adds a screen. The feature generator does not edit the router.

## Theme

`AppTheme.light` and `AppTheme.dark` are Material 3 themes seeded from `AppColors.brand`. `AppStatusColors` adds success, warning, border, and disabled colors. Spacing, radius, and typography have their own files. `ThemeModeController.setThemeMode` stores light, dark, or system in shared preferences and restores it on startup. System mode follows the device.

Screens use `context.colors`, `context.textTheme`, and `context.statusColors`. Icons come from `AppIcons`. Remix glyphs are the default fields. Flutter's built-in icons are the Material fields on the same class.

## Responsive layouts

Width comes from `LayoutBuilder`, not from the operating system. `AppBreakpoints` defaults to 600 for tablet and 1024 for desktop.

Three strategies:

1. One screen in `ResponsiveBody`. Login and home use this.
2. `AdaptiveLayout` when the arrangement changes and the next smaller layout can stand in.
3. Separate `screens/mobile`, `screens/tablet`, and `screens/desktop` only when the experience is different. Showcase is the reference. Its three screens share `showcaseControllerProvider`.

`AdaptiveNavigation` draws a bottom bar, a rail, or a sidebar. Use it only when the screen needs that chrome.

## Logging

`AppLogger` is the only logger. It wraps `flutter_devlog`. Development shows every level, staging keeps warnings and errors, and production disables logging. Do not call `print` or `DevLog` from a feature. Do not log passwords, tokens, or the `Authorization` header.

## Code generation

Freezed is used for API models and for immutable state such as `AuthState`. `Result` and `Failure` stay handwritten sealed types. Enums and services stay ordinary classes. After a model change, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the generated files. Do not edit them.

## Where the rules live

`.agent/rules/` is the short, enforceable convention set. This document explains the same system for someone reading the repository for the first time. If they disagree, the code and the validator win, and the doc should be corrected.

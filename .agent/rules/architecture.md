# Architecture

Features are independent. A feature owns its UI, state, use cases, repository contract, and data sources.

```text
lib/features/<feature>/
  data/datasources
  data/models
  data/providers
  data/repositories
  domain/entities
  domain/repositories
  domain/usecases
  presentation/providers
  presentation/layout
  presentation/screens
  presentation/screens/mobile
  presentation/screens/tablet
  presentation/screens/desktop
  presentation/widgets
  presentation/widgets/shared
```

Add `data` and `domain` when the feature talks to an API or enforces a business rule. A static screen can stay presentation-only, as `home` does.

Create `screens/tablet` and `screens/desktop` only when that layout differs from mobile. The showcase feature is the reference. Login and home stay one responsive screen.

## Dependency direction

```text
presentation -> domain -> (nothing in Flutter, material_ui, or Dio)
data -> domain
data -> core
presentation -> core
```

Domain files import entities, repository contracts, and `Result`. They do not import `package:flutter` or `package:dio`.

Screens and widgets do not import a feature `data` folder or `package:dio`. A presentation provider may import the same feature's `data/providers` to wire use cases. It still calls the use case, not Dio.

`lib/core/routing` may import feature screens and presentation providers. It does not import feature data or domain.

## Where code goes

- `lib/core`: the Dio client, storage, theme, router, failures, and app-wide widgets
- `lib/shared`: widgets and types used by more than one feature
- `lib/features/<feature>`: everything else for that feature

## Do not

- Import `lib/features/auth/data` from `lib/features/home`.
- Import a data source from a screen or widget.
- Call `Dio` from a widget.
- Put a repository implementation in `domain`.
- Create a second `ProviderScope` inside a feature.

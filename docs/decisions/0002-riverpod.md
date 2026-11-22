# Riverpod for state and dependency injection

## Context

Screens need a place for session, theme, and network state, and a way to construct repositories without a service locator hidden in widgets.

## Decision

Use `flutter_riverpod` `Notifier` and `Provider`. `main.dart` overrides environment and preferences at the root `ProviderScope`. Features do not create another scope. Do not write `state` during `build`. Generated lists use `RequestGate`.

## Alternatives considered

- **Bloc / Cubit.** Strong for large teams with event-driven flows. Heavier for a starter that only needs a few notifiers and test overrides.
- **Provider.** Fine for simple InheritedWidget-style DI. It does not give Notifier lifecycle or the same override story Riverpod gives in tests.
- **GetX.** Mixes routing, DI, and state with a different style than this feature-first layout. Keeping one approach is clearer for a template.
- `package:provider` or a hand-rolled `InheritedWidget` for DI only. They do not give the same notifier lifecycle.
- A second state library beside Riverpod. Two sources of truth make the starter harder to learn.
- Riverpod code generation. The template stays on hand-written providers so a reader can see the wiring.

## Consequences

Overrides in tests replace storage and environment without a widget calling a constructor. Contributors must learn Notifier. They do not also learn a second state package.

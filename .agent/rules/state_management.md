# State management

Riverpod is the only state and dependency-injection tool.

- Expose a `Notifier<FeatureState>` for state that changes over time.
- Use Freezed for that state when it needs equality and `copyWith`. See `.agent/rules/code_generation.md`.
- Expose a `Provider` for repositories, use cases, and clients.
- Read dependencies with `ref.watch` in `build` and `ref.read` inside callbacks.
- Keep the notifier in `presentation/providers`.
- Represent async screen state with an explicit status, not a bare nullable.
- Check `ref.mounted` after an `await` before assigning `state`.
- Do not assign `state` synchronously inside `build`. Return the loading or idle state first. `RequestGate.schedule` starts the request on a later turn and ignores the result after disposal.
- Override providers in tests. Do not call a real plugin from a unit test.

`setState` is only for text controllers, focus, and other state that belongs to one widget and never leaves it.

## Do not

- Add `get_it`, `provider`, Bloc, or a second `Dio` singleton.
- Use Riverpod code generation unless the task asks for it. Hand-written notifiers are the project default.
- Watch a provider from a repository.

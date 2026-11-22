# New feature

Prefer the generator from the project root:

```bash
dart run :fcar feature create products
dart run :fcar feature create products --dry-run
dart run :fcar feature create settings --presentation-only
```

`products` creates data, domain, and presentation files, plus a repository test and a screen test. The remote data source throws `UnimplementedError` until an approved endpoint exists. The command does not edit `app_router.dart` and does not replace existing files unless `--force` is set. `--dry-run` prints the file list.

After a full feature, register a `GoRoute` in `lib/core/routing/app_router.dart`.

Do the same steps by hand when the feature does not match the template:

1. Read `.agent/rules/architecture.md` and the closest existing feature.
2. Create `lib/features/<feature>/` and only the layers the feature needs.
3. Add an entity and a repository contract before the data source.
4. Implement the data source and repository. Return `Result<T>`.
5. Add a use case for each screen action.
6. Add a `Notifier` and provider in `presentation/providers`. Put Dio and repository construction in `data/providers`.
7. Add the screen and register a `GoRoute` in `lib/core/routing/app_router.dart`.
8. Reuse widgets from `lib/core/widgets` and `lib/shared/widgets`.
9. Add a unit test for the repository or use case and a widget test for the main interaction.
10. Run `dart format`, `flutter analyze`, and `flutter test`.

A feature starts with one mobile screen. When a tablet or desktop design is actually different, add that screen beside it and select it with `AdaptiveLayout`. Keep the same provider. The showcase feature under `lib/features/showcase` is the working example. Layout rules are in `.agent/rules/flutter_ui.md`.

Do not import another feature's data or domain layer. Navigate with a route path instead. Do not invent an endpoint in the generated data source.

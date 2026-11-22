# Testing

- Put unit tests in `test/unit`, mirroring the library path.
- Put widget tests in `test/widget`.
- Reserve `test/integration` for flows that need a device. Do not put unit tests there.
- Use `flutter_test` and `mocktail`.
- Override `authRepositoryProvider` or pass a fake data source. Do not call the network.
- Cover the success path and one failure path for a repository you touch.
- A form test should submit empty input and expect the validation message.
- Layout tests set a logical width. Cover mobile, tablet, desktop, a width change, and a missing larger layout. Do not assume a device model.

Run this before finishing:

```bash
dart format .
flutter analyze
flutter test
dart run :fcar validate
```

CI runs the same checks, then builds the web app and checks that committed generated files still match `build_runner`.

A change to the rename, create, feature, or validate CLI also needs a fixture test under `test/unit/tool`. Do not rename the live template as a test. Feature generator tests pass `runCodegen: false` and use a temporary directory.

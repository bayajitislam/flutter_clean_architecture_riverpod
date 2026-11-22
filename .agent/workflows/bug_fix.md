# Bug fix

1. Reproduce the failure with a test or a precise manual step.
2. Find the layer that owns the bug. Do not patch a repository error inside a widget if the repository returns the wrong `Result`.
3. Change the smallest set of files that fixes the cause.
4. Add a regression test next to the existing unit or widget tests.
5. Run `flutter analyze` and the tests that cover the change.
6. Report the cause, the files changed, and any case you could not run.

Do not silence the exception, delete the failing test, or refactor an unrelated feature in the same change.

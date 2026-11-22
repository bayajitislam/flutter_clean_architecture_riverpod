# Create an application

Flutter Clean Architecture Riverpod is the starter kit. A generated application is a separate project with its own name, README, and docs. It does not keep this repository's contribution files, and it does not receive starter changes automatically.

## Command line

From this repository:

```bash
dart run tool/awesome.dart create my_shop --output ../my_shop
```

`dart run :awesome create my_shop` does the same thing. The package name is `my_shop`. The display name defaults to `My Shop`. The bundle id keeps the current organization prefix and replaces the last segment.

Useful flags:

| Flag | Default |
| --- | --- |
| `--display-name` | Title case of the package name |
| `--bundle-id` | Organization prefix plus the package name |
| `--description` | `A Flutter application.` |
| `--brand-color` | The starter brand color |
| `--platforms` | `android,ios,web,macos,linux,windows` |
| `--showcase` | Off. Pass it to copy the layout showcase. |
| `--no-auth` | Off. Pass it to leave out sample sign-in. |
| `--dry-run` | Print the plan and do not write. |
| `--force` | Replace a non-empty output directory. |

On a terminal, a missing package name is prompted. Every other value has a default, so the command does not ask a series of questions.

`--dry-run` is safe. The starter checkout is not modified. Firebase files, entitlements, and URL schemes are copied and not rewritten. Local `env/*.json`, signing files, and machine SDK paths are not copied.

## GitHub template

1. In the repository settings, mark this repository as a template.
2. Use **Use this template** to create a new repository. Do not use it to edit this starter.
3. Clone that new repository.
4. Initialize it:

```bash
dart run tool/awesome.dart init my_shop --display-name "My Shop"
```

`init` rewrites that checkout in place. It records a snapshot under `.awesome-backup/` first. If initialization fails, that snapshot is restored. The folder is gitignored. Delete it after you have checked the result.

Running `init` again with the same package name does nothing. Pass `--force` only to rename an application that was already initialized. A forced run does not delete features you added.

Do not run `init` in a checkout you still want to keep as the Flutter Clean Architecture Riverpod starter.

## What the new application contains

It keeps the architecture, theme, logging, Riverpod, GoRouter, Dio, tests, platform projects you selected, and the feature generator.

It drops this starter's issue templates, pull request template, code of conduct, contributing guide, and starter decision records. It writes its own `README.md`, `AGENTS.md`, `docs/architecture.md`, `docs/development.md`, and `docs/updates.md`.

The showcase is omitted unless you pass `--showcase`. Sample sign-in stays unless you pass `--no-auth`. Responsive layout helpers stay either way. They are application infrastructure, not a demo.

`tool/app_manifest.yaml` records the starter version used to generate the app. Read `docs/updates.md` in the new app before copying a later starter change by hand.

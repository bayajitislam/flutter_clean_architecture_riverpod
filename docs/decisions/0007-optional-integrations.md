# Optional products stay out of the template

## Context

Firebase, a local database, subscriptions, localization, and an offline cache are common, and they are not common to every app.

## Decision

The template does not depend on them. `AppEnv` can omit the API URL in development and use a fake auth source. Staging and production require a URL. The rename command does not rewrite signing files, entitlements, URL schemes, or Firebase config files, because those belong to a specific app.

## Alternatives considered

- Install the packages behind flags. Unused native setup still has to be maintained.
- A plugin system that downloads them. That is a second package manager.

## Consequences

The dependency list stays reviewable. A team that needs Firebase adds it in the generated app and keeps its config files out of this repository. The starter does not pretend those integrations are done.

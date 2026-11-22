# Use package:material_ui instead of package:flutter/material.dart

## Context

Flutter 3.47 shipped Material and Cupertino as standalone packages. Flutter 3.50 deprecates `package:flutter/material.dart` and tells apps to import `package:material_ui/material_ui.dart` instead. CI on current stable fails `flutter analyze` when the old import remains.

## Decision

Depend on `material_ui` and import `package:material_ui/material_ui.dart` in app and test code. Domain code must not import `material_ui` either. `validate` treats `package:material_ui/` the same as Flutter UI imports for the domain layer.

## Alternatives considered

- Keep `package:flutter/material.dart` and ignore the deprecation. That fails analyzer on current stable and leaves the starter behind the migration.
- Pin an older Flutter forever. The starter would stop matching what newcomers install.

## Stability

`material_ui` is the official Material library from the Flutter team on pub.dev. Version 1.x matches the Material API that used to live in the SDK. Prefer a caret constraint (`^1.2.0`) and let Dependabot propose upgrades. Treat a major bump of `material_ui` as a breaking change for generated apps.

## Consequences

Contributors must not write `import 'package:flutter/material.dart';`. Feature generators emit `material_ui` imports. Third-party packages that still use the old import may need a compatibility bridge later; that bridge is temporary and should not become a permanent pattern in feature code.

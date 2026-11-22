import 'dart:io';

import 'package:yaml/yaml.dart';

import 'identity.dart';
import 'project_exception.dart';
import 'rename_project.dart';

const knownPlatforms = {'android', 'ios', 'web', 'macos', 'linux', 'windows'};

const defaultDescription = 'A Flutter application.';

/// Choices for a new application. Null strings keep the starter default.
class HandoffOptions {
  const HandoffOptions({
    required this.packageName,
    this.displayName,
    this.bundleId,
    this.description,
    this.brandColor,
    this.platforms = knownPlatforms,
    this.includeShowcase = false,
    this.includeAuth = true,
  });

  final String packageName;
  final String? displayName;
  final String? bundleId;
  final String? description;
  final String? brandColor;
  final Set<String> platforms;
  final bool includeShowcase;
  final bool includeAuth;
}

class AppManifest {
  const AppManifest({
    required this.packageName,
    required this.starterVersion,
    required this.includeShowcase,
    required this.includeAuth,
  });

  static const relativePath = 'tool/app_manifest.yaml';

  final String packageName;
  final String starterVersion;
  final bool includeShowcase;
  final bool includeAuth;

  static AppManifest? tryLoad(Directory root) {
    final file = File(_join(root.path, relativePath));
    if (!file.existsSync()) {
      return null;
    }
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      return null;
    }
    final packageName = document['package_name'];
    if (packageName is! String || packageName.isEmpty) {
      return null;
    }
    return AppManifest(
      packageName: packageName,
      starterVersion: '${document['starter_version'] ?? ''}',
      includeShowcase: document['include_showcase'] == true,
      includeAuth: document['include_auth'] != false,
    );
  }
}

/// Turns a copied starter checkout into an independent application.
///
/// [renameProject] must already have applied [options.packageName].
List<String> finalizeApplication(
  Directory root, {
  required HandoffOptions options,
  required String starterVersion,
}) {
  final description = _description(options.description);
  final brand = options.brandColor == null
      ? null
      : normalizeBrandColor(options.brandColor!);
  _validatePlatforms(options.platforms);
  final identity = ProjectIdentity.load(root);
  final notes = <String>[];

  _writeText(
    root,
    ProjectIdentity.relativePath,
    ProjectIdentity(
      packageName: identity.packageName,
      displayName: identity.displayName,
      bundleId: identity.bundleId,
      description: description,
    ).toYaml(),
  );
  _replaceDescription(root, description);
  _replaceAppName(root, identity.displayName);
  if (brand != null) {
    _replaceBrand(root, brand);
    notes.add('Set the brand color to $brand.');
  }

  for (final platform in knownPlatforms.difference(options.platforms)) {
    final directory = Directory(_join(root.path, platform));
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
      notes.add('Removed the $platform project.');
    }
  }

  if (!options.includeShowcase) {
    _removeShowcase(root);
    notes.add('Left out the showcase feature.');
  }
  if (!options.includeAuth) {
    _removeAuth(root, identity.packageName);
    notes.add('Left out the sample sign-in feature.');
  }

  _removeStarterCommunityFiles(root);
  _writeApplicationDocs(
    root,
    identity: identity,
    description: description,
    starterVersion: starterVersion,
    includeShowcase: options.includeShowcase,
    includeAuth: options.includeAuth,
  );
  notes.add('Wrote the application README and docs.');
  return notes;
}

List<String> handoffPlan(HandoffOptions options) {
  final description = _description(options.description);
  if (options.brandColor != null) {
    normalizeBrandColor(options.brandColor!);
  }
  _validatePlatforms(options.platforms);
  return [
    'Package ${options.packageName}.',
    'Description "$description".',
    if (!options.includeShowcase) 'Exclude the showcase feature.',
    if (options.includeShowcase) 'Keep the showcase feature.',
    if (options.includeAuth) 'Keep sample sign-in.',
    if (!options.includeAuth) 'Exclude sample sign-in.',
    'Platforms: ${options.platforms.join(', ')}.',
    'Replace the starter README, community docs, and issue templates.',
  ];
}

/// Rebrands the current checkout. Used after "Use this template" on GitHub.
///
/// A second run with the same package name changes nothing. Pass [force] to
/// rename an application that was already initialized. Demo content is not
/// removed again.
List<String> initProject({
  required Directory root,
  required HandoffOptions options,
  bool dryRun = false,
  bool force = false,
}) {
  validatePackageName(options.packageName);
  if (options.displayName != null) {
    validateDisplayName(options.displayName!);
  }
  if (options.bundleId != null) {
    validateBundleId(options.bundleId!);
  }
  final existing = AppManifest.tryLoad(root);
  if (existing != null && !force) {
    if (existing.packageName == options.packageName) {
      return ['Already initialized as ${existing.packageName}.'];
    }
    throw ProjectToolException(
      'Already initialized as ${existing.packageName}. '
      'Pass --force to rename it. Demo content is left as it is.',
    );
  }
  if (dryRun) {
    return handoffPlan(options);
  }

  final snapshot = _snapshot(root);
  try {
    if (existing != null && force) {
      final outcome = renameProject(
        root,
        request: RenameRequest(
          packageName: options.packageName,
          displayName: options.displayName,
          bundleId: options.bundleId,
        ),
      );
      if (options.brandColor != null) {
        _replaceBrand(root, normalizeBrandColor(options.brandColor!));
      }
      if (options.description != null) {
        final identity = ProjectIdentity.load(root);
        _writeText(
          root,
          ProjectIdentity.relativePath,
          ProjectIdentity(
            packageName: identity.packageName,
            displayName: identity.displayName,
            bundleId: identity.bundleId,
            description: _description(options.description),
          ).toYaml(),
        );
        _replaceDescription(root, _description(options.description));
      }
      _writeManifest(
        root,
        identity: ProjectIdentity.load(root),
        starterVersion: existing.starterVersion,
        includeShowcase: existing.includeShowcase,
        includeAuth: existing.includeAuth,
      );
      return [
        for (final change in outcome.changes)
          '${change.action} ${change.path} (${change.summary})',
        'Updated the initialized application.',
      ];
    }

    final current = ProjectIdentity.load(root);
    final starterVersion = _pubspecVersion(root);
    final outcome = renameProject(
      root,
      request: RenameRequest(
        packageName: options.packageName,
        displayName:
            options.displayName ?? titleFromPackageName(options.packageName),
        bundleId:
            options.bundleId ??
            bundleIdFromPackageName(current.bundleId, options.packageName),
      ),
    );
    final notes = finalizeApplication(
      root,
      options: options,
      starterVersion: starterVersion,
    );
    return [
      for (final change in outcome.changes)
        '${change.action} ${change.path} (${change.summary})',
      ...notes,
    ];
  } on Object {
    _restoreSnapshot(root, snapshot);
    rethrow;
  }
}

String normalizeBrandColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
    throw ProjectToolException(
      'Brand color must be a 6-digit hex color, such as #1565C0.',
    );
  }
  return '0xFF${hex.toUpperCase()}';
}

Set<String> parsePlatforms(String? value) {
  if (value == null || value.trim().isEmpty) {
    return knownPlatforms;
  }
  final names = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet();
  final unknown = names.difference(knownPlatforms);
  if (names.isEmpty || unknown.isNotEmpty) {
    throw ProjectToolException(
      'Platforms must be a comma-separated list of: '
      '${knownPlatforms.join(', ')}.',
    );
  }
  return names;
}

String _description(String? value) {
  final description = (value ?? defaultDescription).trim();
  if (description.isEmpty ||
      description.length > 120 ||
      description.contains('\n')) {
    throw ProjectToolException(
      'Description must be one line of 1 to 120 characters.',
    );
  }
  return description;
}

void _validatePlatforms(Set<String> platforms) {
  if (platforms.isEmpty || !knownPlatforms.containsAll(platforms)) {
    throw ProjectToolException(
      'Platforms must be chosen from: ${knownPlatforms.join(', ')}.',
    );
  }
}

String _pubspecVersion(Directory root) {
  final document = loadYaml(_read(root, 'pubspec.yaml'));
  if (document is YamlMap && document['version'] is String) {
    return document['version'] as String;
  }
  return '0.0.0';
}

void _replaceDescription(Directory root, String description) {
  final path = 'pubspec.yaml';
  final source = _read(root, path);
  final updated = source.replaceFirst(
    RegExp(r'^description:.*$', multiLine: true),
    'description: ${quoteYaml(description)}',
  );
  _writeText(root, path, updated);
}

void _replaceAppName(Directory root, String displayName) {
  for (final name in ['dev', 'staging', 'prod']) {
    final path = 'env/$name.json.example';
    final file = File(_join(root.path, path));
    if (!file.existsSync()) {
      continue;
    }
    final updated = file.readAsStringSync().replaceAll(
      RegExp(r'"APP_NAME"\s*:\s*"[^"]*"'),
      '"APP_NAME": ${quoteYaml(displayName)}',
    );
    file.writeAsStringSync(updated);
  }
}

void _replaceBrand(Directory root, String colorValue) {
  const path = 'lib/core/theme/app_colors.dart';
  final file = File(_join(root.path, path));
  if (!file.existsSync()) {
    return;
  }
  final source = file.readAsStringSync();
  final updated = source.replaceFirst(
    RegExp(r'static const brand = Color\(0x[A-Fa-f0-9]+\);'),
    'static const brand = Color($colorValue);',
  );
  if (updated == source) {
    throw ProjectToolException('Could not find AppColors.brand in $path.');
  }
  file.writeAsStringSync(updated);
}

void _removeShowcase(Directory root) {
  _deleteDirectory(root, 'lib/features/showcase');
  _deleteDirectory(root, 'test/widget/features/showcase');
  _editIfPresent(root, 'lib/core/routing/app_router.dart', (source) {
    final withoutImport = source.replaceAll(
      RegExp(r"import 'package:[^']+/features/showcase/[^']+';\n"),
      '',
    );
    return _removeRoute(withoutImport, 'RoutePaths.showcase');
  });
  _editIfPresent(root, 'lib/core/routing/route_paths.dart', (source) {
    return source.replaceAll(
      RegExp(r"\n\s*static const showcase = '/showcase';"),
      '',
    );
  });
  _editIfPresent(
    root,
    'lib/features/home/presentation/screens/home_screen.dart',
    (source) {
      final withoutButton = source.replaceAll(
        RegExp(
          r'\n\s*OutlinedButton\(\s*\n\s*onPressed: \(\) => context\.go\(RoutePaths\.showcase\),[\s\S]*?\),\n\s*const SizedBox\(height: 12\),',
        ),
        '',
      );
      return withoutButton
          .replaceAll(
            RegExp(r"import 'package:[^']+/core/routing/route_paths\.dart';\n"),
            '',
          )
          .replaceAll("import 'package:go_router/go_router.dart';\n", '');
    },
  );
}

void _removeAuth(Directory root, String packageName) {
  _deleteDirectory(root, 'lib/features/auth');
  _deleteDirectory(root, 'test/unit/features/auth');
  _deleteFile(root, 'test/widget/login_screen_test.dart');
  _deleteFile(root, 'test/widget/app_theme_mode_test.dart');
  _writeText(root, 'lib/core/routing/route_paths.dart', '''
/// Route paths composed by the app router.
abstract final class RoutePaths {
  static const home = '/';
}
''');
  _writeText(
    root,
    'lib/core/routing/app_router.dart',
    _library(
      [
        'package:$packageName/core/routing/route_paths.dart',
        'package:$packageName/features/home/presentation/screens/home_screen.dart',
        'package:flutter_riverpod/flutter_riverpod.dart',
        'package:go_router/go_router.dart',
      ],
      '''
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
''',
    ),
  );
  _writeText(
    root,
    'lib/features/home/presentation/screens/home_screen.dart',
    _library(
      [
        'package:$packageName/core/extensions/context_extensions.dart',
        'package:$packageName/core/icons/app_icons.dart',
        'package:$packageName/core/theme/app_spacing.dart',
        'package:$packageName/core/theme/theme_mode_controller.dart',
        'package:$packageName/shared/widgets/responsive_body.dart',
        'package:flutter/material.dart',
        'package:flutter_riverpod/flutter_riverpod.dart',
      ],
      '''
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: _nextTheme(themeMode).tooltip,
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).toggle(),
            icon: Icon(_nextTheme(themeMode).icon),
          ),
        ],
      ),
      body: ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Text('Welcome', style: context.textTheme.headlineSmall),
        ),
      ),
    );
  }
}

({IconData icon, String tooltip}) _nextTheme(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => (
      icon: AppIcons.darkMode,
      tooltip: 'Use dark theme',
    ),
    ThemeMode.dark => (
      icon: AppIcons.systemMode,
      tooltip: 'Use system theme',
    ),
    ThemeMode.system => (
      icon: AppIcons.lightMode,
      tooltip: 'Use light theme',
    ),
  };
}
''',
    ),
  );
}

void _removeStarterCommunityFiles(Directory root) {
  for (final path in [
    'CONTRIBUTING.md',
    'CODE_OF_CONDUCT.md',
    'SECURITY.md',
    'LICENSE',
    '.github/PULL_REQUEST_TEMPLATE.md',
  ]) {
    _deleteFile(root, path);
  }
  _deleteFile(root, 'test/unit/tool/handoff_test.dart');
  _deleteFile(root, 'test/integration/generated_app_test.dart');
  _deleteDirectory(root, '.github/ISSUE_TEMPLATE');
  _deleteDirectory(root, 'docs/decisions');
  _deleteDirectory(root, 'docs/guides');
  _deleteDirectory(root, 'docs/architecture');
}

void _writeApplicationDocs(
  Directory root, {
  required ProjectIdentity identity,
  required String description,
  required String starterVersion,
  required bool includeShowcase,
  required bool includeAuth,
}) {
  final features = <String>[
    if (includeAuth)
      'Email sign-in. An empty API URL uses a fake source. A real URL calls `POST /auth/sign-in`.',
    'Light, dark, and system themes from `AppColors.brand`.',
    'Feature-first folders for new work.',
    if (includeShowcase)
      'A layout showcase at `/showcase` for mobile, tablet, and desktop.',
  ];
  _writeText(
    root,
    'README.md',
    _readme(
      identity: identity,
      description: description,
      features: features,
      starterVersion: starterVersion,
      includeAuth: includeAuth,
    ),
  );
  _writeText(
    root,
    'AGENTS.md',
    _agents(identity: identity, includeAuth: includeAuth),
  );
  _writeText(root, 'CHANGELOG.md', '''
# Changelog

## [Unreleased]

- Created ${identity.displayName} from Flutter Clean Architecture Riverpod $starterVersion.
''');
  _writeText(root, 'docs/architecture.md', _architecture(includeAuth));
  _writeText(root, 'docs/development.md', _development(includeAuth));
  _writeText(root, 'docs/updates.md', _updates(starterVersion));
  _writeText(root, '.github/workflows/ci.yml', '''
name: CI

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test
      - run: dart run tool/awesome.dart validate
      - run: flutter build web
''');
  _writeManifest(
    root,
    identity: identity,
    starterVersion: starterVersion,
    includeShowcase: includeShowcase,
    includeAuth: includeAuth,
  );
  _formatProject(root);
}

void _writeManifest(
  Directory root, {
  required ProjectIdentity identity,
  required String starterVersion,
  required bool includeShowcase,
  required bool includeAuth,
}) {
  _writeText(root, AppManifest.relativePath, '''
role: application
starter_name: flutter_clean_architecture_riverpod
starter_version: ${quoteYaml(starterVersion)}
package_name: ${quoteYaml(identity.packageName)}
display_name: ${quoteYaml(identity.displayName)}
include_showcase: $includeShowcase
include_auth: $includeAuth
''');
}

void _formatProject(Directory root) {
  final result = Process.runSync('dart', [
    'format',
    '.',
  ], workingDirectory: root.path);
  if (result.exitCode != 0) {
    final output = '${result.stdout}${result.stderr}'.trim();
    throw ProjectToolException(output.isEmpty ? 'dart format failed.' : output);
  }
}

String _readme({
  required ProjectIdentity identity,
  required String description,
  required List<String> features,
  required String starterVersion,
  required bool includeAuth,
}) {
  final featureList = features.map((item) => '- $item').join('\n');
  final authSetup = includeAuth
      ? '''
Copy `env/dev.json.example` to `env/dev.json`. Leave `API_BASE_URL` empty to use the fake sign-in source. Set it when the API is ready. Staging and production refuse to start when the URL is empty.

```bash
flutter run --dart-define-from-file=env/dev.json
flutter build apk --dart-define-from-file=env/prod.json
flutter build ipa --dart-define-from-file=env/prod.json
flutter build web --dart-define-from-file=env/prod.json
```

Sign-in stores a token in secure storage. Do not commit `env/*.json`, `key.properties`, or a keystore.
'''
      : '''
Copy `env/dev.json.example` to `env/dev.json` before pointing the app at an API.

```bash
flutter run --dart-define-from-file=env/dev.json
flutter build apk --dart-define-from-file=env/prod.json
flutter build web --dart-define-from-file=env/prod.json
```

Do not commit `env/*.json`, `key.properties`, or a keystore.
''';
  return '''
<!-- identity:start -->
# ${identity.displayName}

- Package name: `${identity.packageName}`
- Display name: ${identity.displayName}
- Bundle id: `${identity.bundleId}`
<!-- identity:end -->

$description

## Features

$featureList

Screenshots are not included. Add them here when the product UI is ready.

## Stack

Flutter, Riverpod, GoRouter, and Dio. The theme, logging, and network client live in `lib/core`. Why those pieces exist is in [docs/architecture.md](docs/architecture.md).

## Project structure

```text
lib/core        shared infrastructure
lib/features    one folder per feature
lib/shared      widgets used by more than one feature
test/unit
test/widget
```

## Setup

Install Flutter stable with a Dart SDK that satisfies `pubspec.yaml`.

```bash
flutter pub get
```

$authSetup
## Development

Day-to-day commands, screens, widgets, features, tests, and release builds are in [docs/development.md](docs/development.md).

Change `AppColors.brand` to recolor the app. Add a feature with:

```bash
dart run tool/awesome.dart feature create orders
```

Then register its screen in `lib/core/routing/app_router.dart`.

## Environment

| Name | Purpose |
| --- | --- |
| `FLAVOR` | `dev`, `staging`, or `prod` |
| `API_BASE_URL` | API origin. Empty in development uses local sample behavior where that exists. |
| `APP_NAME` | Name shown by the app |

Example files in `env/` contain placeholders only.

## Code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the generated files. Do not edit `*.freezed.dart` or `*.g.dart`.

## Testing

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/awesome.dart validate
```

## Release

Follow [docs/development.md](docs/development.md). Signing files stay outside git. Store version numbers use semantic versioning in `pubspec.yaml`.

## License

Choose a license for ${identity.displayName} and add it as `LICENSE`. This repository does not assign one.

This application was generated from the Flutter Clean Architecture Riverpod starter kit, version $starterVersion. Improvements to the starter are not applied automatically. See [docs/updates.md](docs/updates.md).
''';
}

String _agents({required ProjectIdentity identity, required bool includeAuth}) {
  return '''
<!-- identity:start -->
# ${identity.displayName}

- Package name: `${identity.packageName}`
- Display name: ${identity.displayName}
- Bundle id: `${identity.bundleId}`
<!-- identity:end -->

This file describes ${identity.displayName}. Follow `.agent/rules/` when changing code.

## Architecture

- Keep a feature under `lib/features/<feature>/{data,domain,presentation}`.
- Domain code must not import Flutter or Dio.
- Screens call use cases. They do not call Dio or import a feature `data` folder.
- Put shared widgets in `lib/shared` and infrastructure in `lib/core`.
- A feature must not import another feature's `data` or `domain` folder.
${includeAuth ? '- Sample sign-in lives in `lib/features/auth`. Do not log tokens or passwords.\n' : ''}
## UI

- Use `Theme.of(context)`, `context.colors`, `context.textTheme`, and `context.statusColors`.
- Use `AppSpacing`, `AppRadius`, and `AppIcons`.
- Change the brand color in `AppColors.brand`.
- Use one responsive screen unless tablet or desktop needs a different layout. Width comes from `LayoutBuilder`.

## Checks

Run `dart format`, `flutter analyze`, `flutter test`, and `dart run tool/awesome.dart validate` before calling a task done.

After a Freezed or JSON model change, run `dart run build_runner build --delete-conflicting-outputs`.
''';
}

String _architecture(bool includeAuth) {
  return '''
# Architecture

Features live in `lib/features/<feature>`. Shared infrastructure lives in `lib/core`. Widgets used by more than one feature live in `lib/shared`.

```text
presentation -> domain
data -> domain
```

Domain code does not import Flutter or Dio. A screen calls a use case. Repositories return `Result<T>`. Riverpod constructs objects. GoRouter owns routes in `lib/core/routing/app_router.dart`.

${includeAuth ? 'Sign-in is the `auth` feature. The router waits on the splash screen until a stored session is restored.\n' : ''}
## Where to add work

- A feature: `lib/features/<feature>/`, or `dart run tool/awesome.dart feature create <name>`.
- A widget used by one feature: `lib/features/<feature>/presentation/widgets/`.
- A widget used by two features: `lib/shared/widgets/`.
- A screen: the feature `presentation/screens/` folder, then a `GoRoute`.
- An API call: a data source behind the shared Dio client. Do not invent a response shape.
- Theme values: `lib/core/theme`. Brand color: `AppColors.brand`.
- A responsive layout: `ResponsiveBody` for one design. `AdaptiveLayout` when the arrangement changes. Separate mobile, tablet, and desktop screens only when the experience is different.

The short rules in `.agent/rules/` match this layout.
''';
}

String _development(bool includeAuth) {
  return '''
# Development

## Daily workflow

1. Copy the env example you need and fill in the API origin. Do not commit that file.
2. ${includeAuth ? 'Keep the fake sign-in source until the API is ready, then set `API_BASE_URL`.' : 'Set `API_BASE_URL` when a backend exists.'}
3. Change `AppColors.brand` for the brand color.
4. Add a screen under the feature that owns it and register a route.
5. Put a reusable widget in `lib/shared/widgets` only when a second feature uses it.
6. Add a feature with `dart run tool/awesome.dart feature create <name>`.
7. Call external services through a repository. Keep keys out of the repo.
8. Add a unit test for the repository and a widget test for the screen.
9. Run the checks below.

## Checks

```bash
dart format .
flutter analyze
flutter test
dart run tool/awesome.dart validate
```

## Release builds

```bash
flutter build apk --dart-define-from-file=env/prod.json
flutter build ipa --dart-define-from-file=env/prod.json
flutter build web --dart-define-from-file=env/prod.json
```

Android signing uses `android/key.properties`, which is gitignored. iOS and macOS signing stay in Xcode. Do not commit certificates, keystores, or production URLs.

Bump `version` in `pubspec.yaml` with semantic versioning. Note user-visible changes in `CHANGELOG.md`.
''';
}

String _updates(String starterVersion) {
  return '''
# Starter kit updates

This application was generated from Flutter Clean Architecture Riverpod $starterVersion. The version is recorded in `tool/app_manifest.yaml`.

The starter kit does not push changes into this repository. Read the starter's changelog, then copy a specific improvement by hand if you want it.

- A patch in the starter is a fix you can usually copy without changing call sites.
- A minor change adds something you can ignore.
- A major change can break a generated app. Read the migration note before copying it.

Keep your own screens, features, and theme edits. Do not replace this project with a fresh copy of the starter.
''';
}

Directory _snapshot(Directory root) {
  final stamp = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('.', '');
  final snapshot = Directory(_join(_join(root.path, '.awesome-backup'), stamp));
  snapshot.createSync(recursive: true);
  for (final entity in root.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    if (name == '.awesome-backup' ||
        name == '.git' ||
        name == '.dart_tool' ||
        name == 'build') {
      continue;
    }
    final target = _join(snapshot.path, name);
    if (entity is Directory) {
      _copyTree(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
  return snapshot;
}

void _restoreSnapshot(Directory root, Directory snapshot) {
  for (final entity in root.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    if (name == '.awesome-backup') {
      continue;
    }
    entity.deleteSync(recursive: true);
  }
  for (final entity in snapshot.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    final target = _join(root.path, name);
    if (entity is Directory) {
      _copyTree(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}

void _copyTree(Directory source, Directory target) {
  target.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    final next = _join(target.path, name);
    if (entity is Directory) {
      _copyTree(entity, Directory(next));
    } else if (entity is File) {
      entity.copySync(next);
    }
  }
}

String _removeRoute(String source, String pathExpression) {
  final lines = source.split('\n');
  final kept = <String>[];
  for (var index = 0; index < lines.length; index++) {
    if (!lines[index].contains('path: $pathExpression')) {
      kept.add(lines[index]);
      continue;
    }
    while (kept.isNotEmpty && !kept.last.contains('GoRoute(')) {
      kept.removeLast();
    }
    if (kept.isNotEmpty && kept.last.contains('GoRoute(')) {
      kept.removeLast();
    }
    while (index < lines.length && !RegExp(r'^\s*\),').hasMatch(lines[index])) {
      index++;
    }
  }
  return kept.join('\n');
}

String _library(List<String> imports, String body) {
  final sorted = [...imports]..sort();
  final directives = sorted.map((uri) => "import '$uri';").join('\n');
  return '$directives\n\n$body';
}

void _editIfPresent(
  Directory root,
  String path,
  String Function(String source) edit,
) {
  final file = File(_join(root.path, path));
  if (!file.existsSync()) {
    return;
  }
  file.writeAsStringSync(edit(file.readAsStringSync()));
}

void _deleteDirectory(Directory root, String path) {
  final directory = Directory(_join(root.path, path));
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}

void _deleteFile(Directory root, String path) {
  final file = File(_join(root.path, path));
  if (file.existsSync()) {
    file.deleteSync();
  }
}

void _writeText(Directory root, String path, String contents) {
  final file = File(_join(root.path, path));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

String _read(Directory root, String path) {
  return File(_join(root.path, path)).readAsStringSync();
}

String _join(String left, String right) {
  final separator = Platform.pathSeparator;
  if (left.endsWith(separator)) {
    return '$left$right';
  }
  return '$left$separator$right';
}

String _baseName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index == -1 ? normalized : normalized.substring(index + 1);
}

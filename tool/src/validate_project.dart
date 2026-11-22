import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:yaml/yaml.dart';

import 'identity.dart';

const requiredProjectPaths = [
  'AGENTS.md',
  'README.md',
  'LICENSE',
  'CONTRIBUTING.md',
  'CODE_OF_CONDUCT.md',
  'SECURITY.md',
  'CHANGELOG.md',
  'docs/architecture/overview.md',
  'docs/architecture/dependencies.md',
  'docs/guides/extending.md',
  'docs/guides/releasing.md',
  'docs/guides/handoff.md',
  'docs/decisions/0001-feature-first-architecture.md',
  '.github/PULL_REQUEST_TEMPLATE.md',
  '.github/ISSUE_TEMPLATE/bug_report.yml',
  '.github/ISSUE_TEMPLATE/feature_request.yml',
  '.github/ISSUE_TEMPLATE/architecture_proposal.yml',
  '.github/ISSUE_TEMPLATE/documentation.yml',
  'tool/cli.dart',
  'tool/project_identity.yaml',
  '.agent/rules/architecture.md',
  '.agent/rules/dart_conventions.md',
  '.agent/rules/flutter_ui.md',
  '.agent/rules/state_management.md',
  '.agent/rules/api_integration.md',
  '.agent/rules/error_handling.md',
  '.agent/rules/testing.md',
  '.agent/rules/security.md',
  '.agent/rules/code_generation.md',
  '.agent/workflows/new_feature.md',
  '.agent/workflows/bug_fix.md',
  '.agent/workflows/code_review.md',
  '.agent/workflows/refactoring.md',
  'lib/core/config',
  'lib/core/constants',
  'lib/core/errors',
  'lib/core/extensions',
  'lib/core/icons/app_icons.dart',
  'lib/core/network',
  'lib/core/routing',
  'lib/core/services',
  'lib/core/state/request_gate.dart',
  'lib/core/storage',
  'lib/core/theme',
  'lib/core/theme/app_colors.dart',
  'lib/core/theme/app_typography.dart',
  'lib/core/theme/app_spacing.dart',
  'lib/core/theme/app_radius.dart',
  'lib/core/theme/app_theme_extensions.dart',
  'lib/core/utils',
  'lib/core/widgets',
  'lib/features/auth/data/datasources',
  'lib/features/auth/data/models',
  'lib/features/auth/data/repositories',
  'lib/features/auth/data/providers',
  'lib/features/auth/domain/entities',
  'lib/features/auth/domain/repositories',
  'lib/features/auth/domain/usecases',
  'lib/features/auth/presentation/providers',
  'lib/features/auth/presentation/screens',
  'lib/features/auth/presentation/widgets',
  'lib/features/home',
  'lib/features/showcase/presentation/layout',
  'lib/features/showcase/presentation/providers',
  'lib/features/showcase/presentation/screens/mobile',
  'lib/features/showcase/presentation/screens/tablet',
  'lib/features/showcase/presentation/screens/desktop',
  'lib/features/showcase/presentation/widgets/shared',
  'lib/shared/widgets',
  'lib/shared/widgets/adaptive_layout.dart',
  'lib/shared/widgets/adaptive_navigation.dart',
  'lib/shared/models',
  'lib/shared/enums',
  'test/unit',
  'test/widget',
  'test/integration',
  'assets/images',
  'assets/icons',
  'assets/fonts',
  'assets/animations',
  'linux/CMakeLists.txt',
  'macos/Runner/Configs/AppInfo.xcconfig',
  'windows/CMakeLists.txt',
  'windows/runner/Runner.rc',
  'web/index.html',
  'web/manifest.json',
  'env/dev.json.example',
  'env/staging.json.example',
  'env/prod.json.example',
  'bin/awesome.dart',
];

const requiredDependencies = [
  'flutter_riverpod',
  'go_router',
  'dio',
  'freezed_annotation',
  'json_annotation',
  'flutter_secure_storage',
  'shared_preferences',
  'flutter_devlog',
  'remixicon',
  'material_ui',
];

class ValidateReport {
  const ValidateReport(this.issues);

  final List<String> issues;

  bool get isValid => issues.isEmpty;
}

/// Checks identity, platform ids, imports, and the required template layout.
///
/// [analyze] runs `flutter analyze` unless [dryRun] is set.
Future<ValidateReport> validateProject(
  Directory root, {
  bool analyze = false,
  bool dryRun = false,
}) async {
  final issues = checkProject(root);
  if (analyze && !dryRun) {
    final result = await Process.run('flutter', [
      'analyze',
    ], workingDirectory: root.path);
    if (result.exitCode != 0) {
      final output = '${result.stdout}${result.stderr}'.trim();
      issues.add(output.isEmpty ? 'flutter analyze failed.' : output);
    }
  }
  return ValidateReport(issues);
}

List<String> checkProject(Directory root) {
  final issues = <String>[];
  final identity = ProjectIdentity.load(root);
  final pubspecFile = File(_join(root.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    issues.add('Missing pubspec.yaml.');
    return issues;
  }
  final pubspecText = pubspecFile.readAsStringSync();
  final document = loadYaml(pubspecText);
  if (document is! YamlMap || document['name'] != identity.packageName) {
    issues.add(
      'pubspec.yaml name does not match ${ProjectIdentity.relativePath}.',
    );
  } else {
    issues.addAll(_importIssues(root, document, identity.packageName));
  }
  if (document is YamlMap) {
    issues.addAll(_dependencyIssues(document));
  }
  if (!packageNamePattern.hasMatch(identity.packageName)) {
    issues.add('Package name in ${ProjectIdentity.relativePath} is invalid.');
  }

  issues
    ..addAll(platformIdentityIssues(root, identity))
    ..addAll(architectureIssues(root, identity.packageName))
    ..addAll(_envIssues(root))
    ..addAll(_generatedFileIssues(root));

  for (final path in requiredProjectPaths) {
    if (_skippedForApplication(root, path)) {
      continue;
    }
    final type = FileSystemEntity.typeSync(_join(root.path, path));
    if (type == FileSystemEntityType.notFound) {
      issues.add('Missing $path.');
    }
  }
  if (_isApplication(root)) {
    for (final path in _applicationPaths) {
      final type = FileSystemEntity.typeSync(_join(root.path, path));
      if (type == FileSystemEntityType.notFound) {
        issues.add('Missing $path.');
      }
    }
  }
  return issues;
}

const _applicationPaths = [
  'docs/architecture.md',
  'docs/development.md',
  'docs/updates.md',
  'tool/app_manifest.yaml',
];

const _starterOnlyPaths = {
  'LICENSE',
  'CONTRIBUTING.md',
  'CODE_OF_CONDUCT.md',
  'SECURITY.md',
  'CHANGELOG.md',
  'docs/architecture/overview.md',
  'docs/architecture/dependencies.md',
  'docs/guides/extending.md',
  'docs/guides/releasing.md',
  'docs/guides/handoff.md',
  'docs/decisions/0001-feature-first-architecture.md',
  '.github/PULL_REQUEST_TEMPLATE.md',
  '.github/ISSUE_TEMPLATE/bug_report.yml',
  '.github/ISSUE_TEMPLATE/feature_request.yml',
  '.github/ISSUE_TEMPLATE/architecture_proposal.yml',
  '.github/ISSUE_TEMPLATE/documentation.yml',
};

bool _isApplication(Directory root) {
  return File(_join(root.path, 'tool/app_manifest.yaml')).existsSync();
}

bool _skippedForApplication(Directory root, String path) {
  if (!_isApplication(root)) {
    return false;
  }
  if (_starterOnlyPaths.contains(path)) {
    return true;
  }
  const featureRoots = {
    'lib/features/auth/': 'lib/features/auth',
    'lib/features/showcase/': 'lib/features/showcase',
  };
  for (final entry in featureRoots.entries) {
    if (path.startsWith(entry.key) &&
        !Directory(_join(root.path, entry.value)).existsSync()) {
      return true;
    }
  }
  const platforms = ['linux', 'macos', 'windows', 'web', 'android', 'ios'];
  for (final platform in platforms) {
    if (path.startsWith('$platform/') &&
        !Directory(_join(root.path, platform)).existsSync()) {
      return true;
    }
  }
  return false;
}

List<String> _importIssues(
  Directory root,
  YamlMap document,
  String packageName,
) {
  final known = <String>{packageName};
  for (final section in ['dependencies', 'dev_dependencies']) {
    final value = document[section];
    if (value is YamlMap) {
      known.addAll(value.keys.map((key) => '$key'));
    }
  }
  final issues = <String>[];
  final pattern = RegExp('package:([A-Za-z0-9_]+)/');
  for (final folder in ['lib', 'test']) {
    final directory = Directory(_join(root.path, folder));
    if (!directory.existsSync()) {
      continue;
    }
    for (final entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final source = entity.readAsStringSync();
      for (final uri in _directiveUris(source, entity.path)) {
        final match = pattern.firstMatch(uri);
        if (match == null) {
          continue;
        }
        final imported = match.group(1)!;
        if (!known.contains(imported)) {
          issues.add(
            '${_relative(root, entity.path)} imports package:$imported, '
            'which is not the project or a declared dependency.',
          );
        }
      }
    }
  }
  return issues;
}

void _compare(
  List<String> issues, {
  required String label,
  required String? actual,
  required String expected,
  required String file,
}) {
  if (actual == null) {
    issues.add('$label is missing in $file. Expected $expected.');
    return;
  }
  if (actual != expected) {
    issues.add('$label is $actual, expected $expected.');
  }
}

/// Checks platform identity for platforms that are present.
///
/// A missing platform directory is optional. A present platform must contain
/// its identity file and the expected id. A missing value is an error.
List<String> platformIdentityIssues(Directory root, ProjectIdentity identity) {
  final issues = <String>[];
  if (_directoryExists(root, 'android')) {
    final gradle = _firstExisting(root, [
      'android/app/build.gradle.kts',
      'android/app/build.gradle',
    ]);
    if (gradle == null) {
      issues.add(
        'Missing android/app/build.gradle.kts or android/app/build.gradle.',
      );
    } else {
      final source = _read(root, gradle);
      _compare(
        issues,
        label: 'Android applicationId',
        actual: _firstMatch(
          source,
          RegExp(
            'applicationId\\s*=\\s*["\']([^"\']+)["\']|applicationId\\s+["\']([^"\']+)["\']',
          ),
        ),
        expected: identity.bundleId,
        file: gradle,
      );
      _compare(
        issues,
        label: 'Android namespace',
        actual: _firstMatch(
          source,
          RegExp(
            'namespace\\s*=\\s*["\']([^"\']+)["\']|namespace\\s+["\']([^"\']+)["\']',
          ),
        ),
        expected: identity.bundleId,
        file: gradle,
      );
    }
    const manifest = 'android/app/src/main/AndroidManifest.xml';
    if (_read(root, manifest) == null) {
      issues.add('Missing $manifest.');
    } else {
      _compare(
        issues,
        label: 'Android label',
        actual: _firstMatch(
          _read(root, manifest),
          RegExp('android:label="([^"]+)"'),
        ),
        expected: identity.displayName,
        file: manifest,
      );
    }
  }
  if (_directoryExists(root, 'ios')) {
    const project = 'ios/Runner.xcodeproj/project.pbxproj';
    if (_read(root, project) == null) {
      issues.add('Missing $project.');
    } else {
      _compare(
        issues,
        label: 'iOS bundle id',
        actual: _appBundleId(_read(root, project)),
        expected: identity.bundleId,
        file: project,
      );
    }
  }
  if (_directoryExists(root, 'macos')) {
    const config = 'macos/Runner/Configs/AppInfo.xcconfig';
    if (_read(root, config) == null) {
      issues.add('Missing $config.');
    } else {
      _compare(
        issues,
        label: 'macOS bundle id',
        actual: _firstMatch(
          _read(root, config),
          RegExp('^PRODUCT_BUNDLE_IDENTIFIER = (.+)\$', multiLine: true),
        ),
        expected: identity.bundleId,
        file: config,
      );
    }
  }
  if (_directoryExists(root, 'linux')) {
    const cmake = 'linux/CMakeLists.txt';
    if (_read(root, cmake) == null) {
      issues.add('Missing $cmake.');
    } else {
      final source = _read(root, cmake);
      _compare(
        issues,
        label: 'Linux application id',
        actual: _firstMatch(
          source,
          RegExp('set\\(APPLICATION_ID "([^"]+)"\\)'),
        ),
        expected: identity.bundleId,
        file: cmake,
      );
      _compare(
        issues,
        label: 'Linux binary name',
        actual: _firstMatch(source, RegExp('set\\(BINARY_NAME "([^"]+)"\\)')),
        expected: identity.packageName,
        file: cmake,
      );
    }
  }
  if (_directoryExists(root, 'windows')) {
    const cmake = 'windows/CMakeLists.txt';
    if (_read(root, cmake) == null) {
      issues.add('Missing $cmake.');
    } else {
      final source = _read(root, cmake);
      _compare(
        issues,
        label: 'Windows project name',
        actual: _firstMatch(
          source,
          RegExp(r'^project\(([A-Za-z0-9_]+)', multiLine: true),
        ),
        expected: identity.packageName,
        file: cmake,
      );
      _compare(
        issues,
        label: 'Windows binary name',
        actual: _firstMatch(source, RegExp('set\\(BINARY_NAME "([^"]+)"\\)')),
        expected: identity.packageName,
        file: cmake,
      );
    }
  }
  if (_directoryExists(root, 'web')) {
    const manifest = 'web/manifest.json';
    if (_read(root, manifest) == null) {
      issues.add('Missing $manifest.');
    } else {
      _compare(
        issues,
        label: 'Web app name',
        actual: _firstMatch(
          _read(root, manifest),
          RegExp('"name"\\s*:\\s*"([^"]+)"'),
        ),
        expected: identity.displayName,
        file: manifest,
      );
    }
  }
  return issues;
}

bool _directoryExists(Directory root, String relative) {
  return FileSystemEntity.typeSync(_join(root.path, relative)) ==
      FileSystemEntityType.directory;
}

String? _firstExisting(Directory root, List<String> paths) {
  for (final path in paths) {
    if (_read(root, path) != null) {
      return path;
    }
  }
  return null;
}

String? _appBundleId(String? source) {
  if (source == null) {
    return null;
  }
  for (final match in RegExp(
    r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
  ).allMatches(source)) {
    final id = match.group(1)!.trim();
    if (!id.endsWith('.RunnerTests') && !id.contains('\$')) {
      return id;
    }
  }
  return null;
}

String? _firstMatch(String? source, RegExp pattern) {
  if (source == null) {
    return null;
  }
  final match = pattern.firstMatch(source);
  if (match == null) {
    return null;
  }
  for (var index = 1; index <= match.groupCount; index++) {
    final value = match.group(index);
    if (value != null) {
      return value.trim();
    }
  }
  return null;
}

String? _read(Directory root, String relative) {
  final file = File(_join(root.path, relative));
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsStringSync();
}

String _relative(Directory root, String absolute) {
  final prefix = '${root.absolute.path}${Platform.pathSeparator}';
  final path = File(absolute).absolute.path;
  final raw = path.startsWith(prefix) ? path.substring(prefix.length) : path;
  return raw.replaceAll('\\', '/');
}

String _join(String left, String right) {
  final separator = Platform.pathSeparator;
  if (left.endsWith(separator)) {
    return '$left$right';
  }
  return '$left$separator$right';
}

List<String> _dependencyIssues(YamlMap document) {
  final issues = <String>[];
  final dependencies = document['dependencies'];
  for (final name in requiredDependencies) {
    if (dependencies is! YamlMap || !dependencies.containsKey(name)) {
      issues.add('Missing dependency $name.');
    }
  }
  return issues;
}

List<String> _envIssues(Directory root) {
  final issues = <String>[];
  for (final flavor in ['dev', 'staging', 'prod']) {
    final path = 'env/$flavor.json.example';
    final text = _read(root, path);
    if (text == null) {
      continue;
    }
    if (!text.contains('"FLAVOR"') || !text.contains('"API_BASE_URL"')) {
      issues.add('$path must define FLAVOR and API_BASE_URL.');
    }
  }
  final gitignore = _read(root, '.gitignore');
  if (gitignore == null || !gitignore.contains('env/*.json')) {
    issues.add('.gitignore must ignore env/*.json.');
  }
  return issues;
}

/// Reports feature boundary violations under `lib/`.
///
/// Directives are read from the Dart AST, so comments and string literals are
/// ignored. Import and export directives are both checked. Relative URIs are
/// resolved from the file that contains them.
///
/// Same-feature presentation providers may import that feature's data
/// providers. Screens and widgets may not. Domain code may not import Flutter
/// or Dio. No file may import another feature's data or domain layer.
List<String> architectureIssues(Directory root, String packageName) {
  final issues = <String>[];
  final lib = Directory(_join(root.path, 'lib'));
  if (!lib.existsSync()) {
    return issues;
  }
  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !_isHandWrittenDart(entity.path)) {
      continue;
    }
    final relative = _relative(root, entity.path);
    final location = _featureLocation(relative);
    final source = entity.readAsStringSync();
    for (final uri in _directiveUris(source, entity.path)) {
      _architectureIssue(
        issues,
        relative: relative,
        location: location,
        uri: uri,
        packageName: packageName,
      );
    }
  }
  return issues;
}

void _architectureIssue(
  List<String> issues, {
  required String relative,
  required _FeatureLocation? location,
  required String uri,
  required String packageName,
}) {
  if (location?.layer == 'domain' && _isFlutterOrDio(uri)) {
    issues.add('$relative imports $uri from domain.');
  }
  if (location?.layer == 'presentation' && uri.startsWith('package:dio/')) {
    issues.add('$relative imports $uri from presentation.');
  }
  final libraryPath = _libraryPath(relative, uri, packageName);
  if (libraryPath == null) {
    return;
  }
  final imported = _featureLocation(libraryPath);
  if (imported == null) {
    return;
  }
  final crossesFeature =
      location == null || location.feature != imported.feature;
  final isDataOrDomain = imported.layer == 'data' || imported.layer == 'domain';
  final screenImportsData =
      location?.layer == 'presentation' &&
      (location?.sub == 'screens' || location?.sub == 'widgets') &&
      imported.layer == 'data';
  if (screenImportsData) {
    issues.add('$relative imports $uri from a screen or widget.');
    return;
  }
  if (crossesFeature && isDataOrDomain) {
    issues.add(
      '$relative imports $uri (${imported.feature} ${imported.layer}).',
    );
  }
}

List<String> _directiveUris(String source, String path) {
  try {
    final parsed = parseString(
      content: source,
      path: path,
      throwIfDiagnostics: false,
    );
    final uris = <String>[];
    for (final directive in parsed.unit.directives) {
      if (directive is! ImportDirective && directive is! ExportDirective) {
        continue;
      }
      final uri = (directive as UriBasedDirective).uri.stringValue;
      if (uri != null) {
        uris.add(uri);
      }
    }
    return uris;
  } on Object {
    return const [];
  }
}

String? _libraryPath(String fromRelative, String uri, String packageName) {
  final packagePrefix = 'package:$packageName/';
  if (uri.startsWith(packagePrefix)) {
    return 'lib/${uri.substring(packagePrefix.length)}';
  }
  if (uri.contains(':')) {
    return null;
  }
  return _resolveRelative(fromRelative, uri);
}

String _resolveRelative(String fromFile, String uri) {
  final parts = fromFile.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
      continue;
    }
    parts.add(segment);
  }
  return parts.join('/');
}

List<String> _generatedFileIssues(Directory root) {
  final issues = <String>[];
  final lib = Directory(_join(root.path, 'lib'));
  if (!lib.existsSync()) {
    return issues;
  }
  final partPattern = RegExp("part\\s+['\"]([^'\"]+)['\"]\\s*;");
  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !_isHandWrittenDart(entity.path)) {
      continue;
    }
    final source = entity.readAsStringSync();
    final parts = partPattern
        .allMatches(source)
        .map((match) => match.group(1)!)
        .toList();
    if (source.contains('@freezed') &&
        !parts.any((part) => part.endsWith('.freezed.dart'))) {
      issues.add('${_relative(root, entity.path)} is @freezed without a part.');
    }
    for (final part in parts) {
      final sibling = File(_join(entity.parent.path, part));
      if (!sibling.existsSync()) {
        issues.add(
          '${_relative(root, entity.path)} is missing generated file $part.',
        );
      }
    }
  }
  return issues;
}

bool _isHandWrittenDart(String path) {
  return path.endsWith('.dart') &&
      !path.endsWith('.g.dart') &&
      !path.endsWith('.freezed.dart');
}

bool _isFlutterOrDio(String uri) {
  return uri.startsWith('package:flutter/') ||
      uri.startsWith('package:material_ui/') ||
      uri.startsWith('package:cupertino_ui/') ||
      uri.startsWith('package:dio/');
}

_FeatureLocation? _featureLocation(String relative) {
  final parts = relative.split('/');
  if (parts.length < 4 || parts[0] != 'lib' || parts[1] != 'features') {
    return null;
  }
  final layer = parts[3];
  if (layer != 'data' && layer != 'domain' && layer != 'presentation') {
    return null;
  }
  return _FeatureLocation(parts[2], layer, parts.length > 4 ? parts[4] : null);
}

class _FeatureLocation {
  const _FeatureLocation(this.feature, this.layer, this.sub);

  final String feature;
  final String layer;
  final String? sub;
}

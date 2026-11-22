import 'dart:io';

import 'package:yaml/yaml.dart';

import 'project_exception.dart';

/// The names the rename command is allowed to change.
class ProjectIdentity {
  const ProjectIdentity({
    required this.packageName,
    required this.displayName,
    required this.bundleId,
    required this.description,
  });

  static const relativePath = 'tool/project_identity.yaml';

  final String packageName;
  final String displayName;
  final String bundleId;
  final String description;

  static ProjectIdentity load(Directory root) {
    final file = File(_join(root.path, relativePath));
    if (!file.existsSync()) {
      throw ProjectToolException(
        'Missing $relativePath. Run this command from the project root.',
      );
    }
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      throw ProjectToolException('$relativePath must be a YAML map.');
    }
    return ProjectIdentity(
      packageName: _requiredString(document, 'package_name'),
      displayName: _requiredString(document, 'display_name'),
      bundleId: _requiredString(document, 'bundle_id'),
      description: _requiredString(document, 'description'),
    );
  }

  String toYaml() {
    return '''
package_name: ${quoteYaml(packageName)}
display_name: ${quoteYaml(displayName)}
bundle_id: ${quoteYaml(bundleId)}
description: ${quoteYaml(description)}
''';
  }
}

/// New values for [renameProject]. Null fields stay as they are.
class RenameRequest {
  const RenameRequest({this.packageName, this.displayName, this.bundleId});

  final String? packageName;
  final String? displayName;
  final String? bundleId;

  bool get isEmpty =>
      packageName == null && displayName == null && bundleId == null;
}

class ProjectChange {
  const ProjectChange({
    required this.path,
    required this.action,
    required this.summary,
  });

  final String path;
  final String action;
  final String summary;
}

class RenameOutcome {
  const RenameOutcome({
    required this.identity,
    required this.changes,
    required this.warnings,
  });

  final ProjectIdentity identity;
  final List<ProjectChange> changes;
  final List<String> warnings;
}

final packageNamePattern = RegExp(r'^[a-z][a-z0-9_]*$');
final bundleIdPattern = RegExp(
  r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
);

void validatePackageName(String name) {
  if (!packageNamePattern.hasMatch(name)) {
    throw ProjectToolException(
      'Package name must be snake_case and start with a letter.',
    );
  }
}

void validateBundleId(String bundleId) {
  if (!bundleIdPattern.hasMatch(bundleId)) {
    throw ProjectToolException('Bundle id must look like com.company.app.');
  }
}

void validateDisplayName(String name) {
  if (name.trim().isEmpty || name.length > 50) {
    throw ProjectToolException('Display name must be 1 to 50 characters.');
  }
  const blocked = ['"', '<', '>', '&', '\n', '\r'];
  if (blocked.any(name.contains)) {
    throw ProjectToolException(
      'Display name cannot contain quotes, newlines, or XML characters.',
    );
  }
}

String titleFromPackageName(String packageName) {
  return packageName
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String bundleIdFromPackageName(String currentBundleId, String packageName) {
  final suffix = packageName.replaceAll('_', '');
  final parts = currentBundleId.split('.');
  if (parts.length < 2) {
    return 'com.example.$suffix';
  }
  final org = parts.sublist(0, parts.length - 1).join('.');
  return '$org.$suffix';
}

String quoteYaml(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _requiredString(YamlMap document, String key) {
  final value = document[key];
  if (value is! String || value.trim().isEmpty) {
    throw ProjectToolException(
      '${ProjectIdentity.relativePath} is missing $key.',
    );
  }
  return value;
}

String _join(String left, String right) {
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$right';
  }
  return '$left${Platform.pathSeparator}$right';
}

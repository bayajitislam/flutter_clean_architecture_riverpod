import 'dart:io';

import 'handoff.dart';
import 'identity.dart';
import 'project_exception.dart';
import 'rename_project.dart';

class CreateOutcome {
  const CreateOutcome({
    required this.output,
    required this.outcome,
    required this.copied,
    this.notes = const [],
  });

  final Directory output;
  final RenameOutcome outcome;
  final bool copied;
  final List<String> notes;
}

/// Copies [source] to [output] and renames the copy.
///
/// The source project is not modified. [dryRun] reports the rename without
/// creating [output].
CreateOutcome createProject({
  required Directory source,
  required Directory output,
  required String packageName,
  String? displayName,
  String? bundleId,
  String? description,
  String? brandColor,
  Set<String> platforms = knownPlatforms,
  bool includeShowcase = false,
  bool includeAuth = true,
  bool dryRun = false,
  bool force = false,
}) {
  final options = HandoffOptions(
    packageName: packageName,
    displayName: displayName,
    bundleId: bundleId,
    description: description,
    brandColor: brandColor,
    platforms: platforms,
    includeShowcase: includeShowcase,
    includeAuth: includeAuth,
  );
  validatePackageName(packageName);
  if (displayName != null) {
    validateDisplayName(displayName);
  }
  if (bundleId != null) {
    validateBundleId(bundleId);
  }
  final notes = handoffPlan(options);
  _rejectNestedOutput(source, output);

  final outputHasFiles = output.existsSync() && output.listSync().isNotEmpty;
  if (outputHasFiles && !force && !dryRun) {
    throw ProjectToolException(
      'Output already exists: ${output.path}. Pass --force to replace it.',
    );
  }

  final identity = ProjectIdentity.load(source);
  final request = RenameRequest(
    packageName: packageName,
    displayName: displayName ?? titleFromPackageName(packageName),
    bundleId:
        bundleId ?? bundleIdFromPackageName(identity.bundleId, packageName),
  );
  if (dryRun) {
    return CreateOutcome(
      output: output,
      outcome: renameProject(source, request: request, dryRun: true),
      copied: false,
      notes: notes,
    );
  }

  if (outputHasFiles) {
    output.deleteSync(recursive: true);
  }
  copyTemplate(source, output);
  try {
    final outcome = renameProject(output, request: request);
    final starterVersion = _versionOf(source);
    final applied = finalizeApplication(
      output,
      options: options,
      starterVersion: starterVersion,
    );
    return CreateOutcome(
      output: output,
      outcome: outcome,
      copied: true,
      notes: applied,
    );
  } on Object {
    if (output.existsSync()) {
      output.deleteSync(recursive: true);
    }
    rethrow;
  }
}

String _versionOf(Directory source) {
  final file = File(_join(source.path, 'pubspec.yaml'));
  if (!file.existsSync()) {
    return '0.0.0';
  }
  final match = RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(file.readAsStringSync());
  return match?.group(1) ?? '0.0.0';
}

void copyTemplate(Directory source, Directory output) {
  output.createSync(recursive: true);
  _copyChildren(source, output);
}

void _copyChildren(Directory source, Directory output) {
  final parent = _baseName(source.path);
  for (final entity in source.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    if (_skippedCopyNames.contains(name)) {
      continue;
    }
    if (entity is File && _skippedFile(name, parent: parent)) {
      continue;
    }
    final target = _join(output.path, name);
    if (entity is Directory) {
      final next = Directory(target)..createSync();
      _copyChildren(entity, next);
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}

void _rejectNestedOutput(Directory source, Directory output) {
  final sourcePath = _normalizePath(source.absolute.path);
  final outputPath = _normalizePath(output.absolute.path);
  final separator = Platform.pathSeparator;
  final nested =
      outputPath == sourcePath ||
      outputPath.startsWith('$sourcePath$separator');
  if (nested) {
    throw ProjectToolException(
      'Output must be outside the source project. '
      'Use an absolute path or omit --output to create a sibling folder.',
    );
  }
}

/// Collapses `.` and `..` so `../app` is not treated as inside the source.
String _normalizePath(String path) {
  final separator = Platform.pathSeparator;
  final parts = <String>[];
  for (final part in path.split(separator)) {
    if (part.isEmpty || part == '.') {
      continue;
    }
    if (part == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
      continue;
    }
    parts.add(part);
  }
  if (path.startsWith(separator)) {
    return '$separator${parts.join(separator)}';
  }
  return parts.join(separator);
}

bool _skippedFile(String name, {required String parent}) {
  final localEnv = parent == 'env' && name.endsWith('.json');
  return localEnv ||
      name.endsWith('.iml') ||
      name.endsWith('.log') ||
      name.endsWith('.jks') ||
      name.endsWith('.keystore') ||
      name == '.flutter-plugins' ||
      name == '.flutter-plugins-dependencies' ||
      name == 'local.properties' ||
      name == 'key.properties' ||
      name == 'Generated.xcconfig' ||
      name == 'flutter_export_environment.sh';
}

const _skippedCopyNames = {
  '.git',
  '.dart_tool',
  '.gradle',
  '.idea',
  '.symlinks',
  'Pods',
  '.awesome-backup',
  'build',
  'coverage',
  'ephemeral',
};

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

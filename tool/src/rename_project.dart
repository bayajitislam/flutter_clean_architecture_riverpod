import 'dart:io';

import 'identity.dart';
import 'project_exception.dart';

const _skippedDirectories = {
  '.git',
  '.dart_tool',
  '.gradle',
  '.idea',
  '.symlinks',
  'Pods',
  'build',
  'coverage',
  'ephemeral',
};

/// Updates the project identity using structured file edits.
///
/// Signing files, Firebase configs, entitlements, and URL schemes are not
/// opened. Pass [dryRun] to report the edits without writing them.
RenameOutcome renameProject(
  Directory root, {
  required RenameRequest request,
  bool dryRun = false,
}) {
  if (request.isEmpty) {
    throw ProjectToolException(
      'Pass a package name, --display-name, or --bundle-id.',
    );
  }

  final current = ProjectIdentity.load(root);
  final packageName = request.packageName ?? current.packageName;
  final displayName = request.displayName ?? current.displayName;
  final bundleId = request.bundleId ?? current.bundleId;
  validatePackageName(packageName);
  validateDisplayName(displayName);
  validateBundleId(bundleId);

  final next = ProjectIdentity(
    packageName: packageName,
    displayName: displayName,
    bundleId: bundleId,
    description: current.description,
  );
  final unchanged =
      packageName == current.packageName &&
      displayName == current.displayName &&
      bundleId == current.bundleId;
  if (unchanged) {
    return RenameOutcome(
      identity: current,
      changes: const [],
      warnings: const [],
    );
  }

  final editor = _ProjectEditor(root);
  if (packageName != current.packageName) {
    _updatePubspecName(editor, current.packageName, packageName);
    _updateDartImports(editor, current.packageName, packageName);
    _updateBinaryNames(editor, current.packageName, packageName);
    _updatePlistNames(
      editor,
      key: 'CFBundleName',
      oldValue: current.packageName,
      newValue: packageName,
      summary: 'bundle name',
    );
  }
  if (displayName != current.displayName) {
    _updateDisplayNames(editor, current.displayName, displayName);
  }
  if (bundleId != current.bundleId) {
    _updateBundleIds(editor, current.bundleId, bundleId);
  }
  _updateIdentityBlock(editor, 'README.md', next);
  _updateIdentityBlock(editor, 'AGENTS.md', next);
  final identityFile = editor.read(ProjectIdentity.relativePath);
  final identityYaml = next.toYaml();
  if (identityFile != identityYaml) {
    editor.update(
      ProjectIdentity.relativePath,
      identityYaml,
      'project identity',
    );
  }

  final warnings = <String>[
    if (bundleId != current.bundleId)
      'Bundle id changes do not update Firebase config, provisioning profiles, '
          'URL schemes, or store listings. Register $bundleId before release builds.',
  ];
  if (!dryRun) {
    editor.apply();
  }
  return RenameOutcome(
    identity: next,
    changes: editor.changes,
    warnings: warnings,
  );
}

void _updatePubspecName(_ProjectEditor editor, String oldName, String newName) {
  const path = 'pubspec.yaml';
  final source = editor.read(path);
  if (source == null) {
    throw ProjectToolException('Missing pubspec.yaml.');
  }
  final pattern = RegExp(
    '^name:\\s*[\'"]?${RegExp.escape(oldName)}[\'"]?\\s*\$',
    multiLine: true,
  );
  if (!pattern.hasMatch(source)) {
    throw ProjectToolException(
      'pubspec.yaml name does not match the identity file.',
    );
  }
  editor.update(
    path,
    source.replaceFirst(pattern, 'name: $newName'),
    'package name',
  );
}

void _updateDartImports(_ProjectEditor editor, String oldName, String newName) {
  for (final folder in ['lib', 'test', 'integration_test']) {
    final directory = Directory(_join(editor.root.path, folder));
    if (!directory.existsSync()) {
      continue;
    }
    for (final file in _listFiles(directory)) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final relative = editor.relative(file.path);
      final source = editor.read(relative);
      if (source == null || !source.contains('package:$oldName/')) {
        continue;
      }
      editor.update(
        relative,
        _sortPackageImports(
          source.replaceAll('package:$oldName/', 'package:$newName/'),
        ),
        'Dart package import',
      );
    }
  }
}

String _sortPackageImports(String source) {
  final lines = source.split('\n');
  var index = 0;
  while (index < lines.length) {
    if (!_isDirective(lines[index])) {
      index++;
      continue;
    }
    final start = index;
    while (index < lines.length && _isDirective(lines[index])) {
      index++;
    }
    final packageIndexes = <int>[
      for (var line = start; line < index; line++)
        if (lines[line].contains('package:')) line,
    ];
    final sorted = [for (final line in packageIndexes) lines[line]]..sort();
    for (var offset = 0; offset < packageIndexes.length; offset++) {
      lines[packageIndexes[offset]] = sorted[offset];
    }
  }
  return lines.join('\n');
}

bool _isDirective(String line) {
  final trimmed = line.trim();
  return trimmed.startsWith('import ') || trimmed.startsWith('export ');
}

void _updateBinaryNames(_ProjectEditor editor, String oldName, String newName) {
  _updateFile(editor, 'linux/CMakeLists.txt', (source) {
    return _replaceSet(source, 'BINARY_NAME', oldName, newName);
  }, 'Linux binary name');
  _updateFile(editor, 'windows/CMakeLists.txt', (source) {
    final named = _replaceSet(source, 'BINARY_NAME', oldName, newName);
    final project = RegExp(
      '^(project\\()${RegExp.escape(oldName)}( )',
      multiLine: true,
    );
    return named.replaceAllMapped(project, (match) {
      return '${match.group(1)}$newName${match.group(2)}';
    });
  }, 'Windows binary name');
  _updateFile(editor, 'macos/Runner/Configs/AppInfo.xcconfig', (source) {
    final pattern = RegExp(
      '^(PRODUCT_NAME = )${RegExp.escape(oldName)}\\s*\$',
      multiLine: true,
    );
    return source.replaceAllMapped(pattern, (match) {
      return '${match.group(1)}$newName';
    });
  }, 'macOS product name');
  _updateFile(editor, 'windows/runner/Runner.rc', (source) {
    var next = _replaceRcValue(source, 'InternalName', oldName, newName);
    next = _replaceRcValue(
      next,
      'OriginalFilename',
      '$oldName.exe',
      '$newName.exe',
    );
    return next;
  }, 'Windows executable name');
  for (final relative in _projectFiles(editor.root, '.pbxproj')) {
    _updateFile(editor, relative, (source) {
      return source
          .replaceAll('$oldName.app', '$newName.app')
          .replaceAllMapped(
            RegExp(
              '^(.*TEST_HOST = .*)/${RegExp.escape(oldName)}(";\\s*)\$',
              multiLine: true,
            ),
            (match) => '${match.group(1)}/$newName${match.group(2)}',
          );
    }, 'product file name');
  }
}

void _updateDisplayNames(
  _ProjectEditor editor,
  String oldName,
  String newName,
) {
  final androidSrc = Directory(_join(editor.root.path, 'android/app/src'));
  if (androidSrc.existsSync()) {
    for (final file in _listFiles(androidSrc)) {
      if (!file.path.endsWith('AndroidManifest.xml')) {
        continue;
      }
      final relative = editor.relative(file.path);
      _updateFile(editor, relative, (source) {
        return source.replaceAll(
          'android:label="$oldName"',
          'android:label="$newName"',
        );
      }, 'Android label');
    }
  }
  _updatePlistNames(
    editor,
    key: 'CFBundleDisplayName',
    oldValue: oldName,
    newValue: newName,
    summary: 'display name',
  );
  _updatePlistNames(
    editor,
    key: 'CFBundleName',
    oldValue: oldName,
    newValue: newName,
    summary: 'display name',
  );
  for (final relative in ['linux/runner/my_application.cc']) {
    _updateFile(editor, relative, (source) {
      final pattern = RegExp(
        r'(gtk_(?:header_bar_set_title|window_set_title)\([^,]+,\s*")([^"]*)("\))',
      );
      return source.replaceAllMapped(pattern, (match) {
        if (match.group(2) != oldName) {
          return match.group(0)!;
        }
        return '${match.group(1)}$newName${match.group(3)}';
      });
    }, 'Linux window title');
  }
  _updateFile(editor, 'windows/runner/Runner.rc', (source) {
    var next = _replaceRcValue(source, 'FileDescription', oldName, newName);
    next = _replaceRcValue(next, 'ProductName', oldName, newName);
    return next;
  }, 'Windows display name');
  _updateFile(editor, 'windows/runner/main.cpp', (source) {
    final pattern = RegExp(r'(window\.Create\(L")([^"]*)(")');
    return source.replaceAllMapped(pattern, (match) {
      if (match.group(2) != oldName) {
        return match.group(0)!;
      }
      return '${match.group(1)}$newName${match.group(3)}';
    });
  }, 'Windows window title');
  _updateFile(editor, 'web/index.html', (source) {
    return source
        .replaceAll('<title>$oldName</title>', '<title>$newName</title>')
        .replaceAll(
          'apple-mobile-web-app-title" content="$oldName"',
          'apple-mobile-web-app-title" content="$newName"',
        );
  }, 'web title');
  _updateFile(editor, 'web/manifest.json', (source) {
    return source
        .replaceAll('"name": "$oldName"', '"name": "$newName"')
        .replaceAll('"short_name": "$oldName"', '"short_name": "$newName"');
  }, 'web manifest name');
}

void _updateBundleIds(_ProjectEditor editor, String oldId, String newId) {
  for (final path in [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
  ]) {
    _updateFile(editor, path, (source) {
      var next = source;
      for (final key in ['namespace', 'applicationId']) {
        final assignment = RegExp(
          '^(\\s*$key\\s*=\\s*")${RegExp.escape(oldId)}(")',
          multiLine: true,
        );
        final groovy = RegExp(
          '^(\\s*$key\\s+")${RegExp.escape(oldId)}(")',
          multiLine: true,
        );
        next = next.replaceAllMapped(assignment, (match) {
          return '${match.group(1)}$newId${match.group(2)}';
        });
        next = next.replaceAllMapped(groovy, (match) {
          return '${match.group(1)}$newId${match.group(2)}';
        });
      }
      return next;
    }, 'Android application id');
  }
  _moveAndroidPackages(editor, oldId, newId);
  for (final relative in _projectFiles(editor.root, '.pbxproj')) {
    _updateFile(editor, relative, (source) {
      return _replaceProductBundleIdentifier(source, oldId, newId);
    }, 'bundle identifier');
  }
  for (final relative in _projectFiles(editor.root, '.xcconfig')) {
    _updateFile(editor, relative, (source) {
      final pattern = RegExp(
        '^(PRODUCT_BUNDLE_IDENTIFIER = )${RegExp.escape(oldId)}\\s*\$',
        multiLine: true,
      );
      return source.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}$newId';
      });
    }, 'bundle identifier');
  }
  _updateFile(editor, 'linux/CMakeLists.txt', (source) {
    return _replaceSet(source, 'APPLICATION_ID', oldId, newId);
  }, 'Linux application id');
}

void _moveAndroidPackages(_ProjectEditor editor, String oldId, String newId) {
  final src = Directory(_join(editor.root.path, 'android/app/src'));
  if (!src.existsSync()) {
    return;
  }
  final packagePattern = RegExp(
    '^package\\s+${RegExp.escape(oldId)}(\\s*;)?\\s*\$',
    multiLine: true,
  );
  for (final file in _listFiles(src)) {
    final isSource = file.path.endsWith('.kt') || file.path.endsWith('.java');
    if (!isSource) {
      continue;
    }
    final relative = editor.relative(file.path);
    final source = editor.read(relative);
    if (source == null || !packagePattern.hasMatch(source)) {
      continue;
    }
    final updated = source.replaceFirstMapped(packagePattern, (match) {
      final semicolon = match.group(1) ?? '';
      return 'package $newId$semicolon';
    });
    final oldSegment = oldId.replaceAll('.', '/');
    final newSegment = newId.replaceAll('.', '/');
    final moved = relative.contains(oldSegment)
        ? relative.replaceFirst(oldSegment, newSegment)
        : relative;
    if (moved == relative) {
      editor.update(relative, updated, 'Android package');
    } else {
      editor.create(moved, updated, 'Android package');
      editor.delete(relative, 'Android package');
    }
  }
}

void _updatePlistNames(
  _ProjectEditor editor, {
  required String key,
  required String oldValue,
  required String newValue,
  required String summary,
}) {
  for (final relative in _projectFiles(editor.root, 'Info.plist')) {
    _updateFile(editor, relative, (source) {
      final pattern = RegExp(
        '(<key>${RegExp.escape(key)}</key>\\s*<string>)${RegExp.escape(oldValue)}(</string>)',
      );
      return source.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}$newValue${match.group(2)}';
      });
    }, summary);
  }
}

void _updateIdentityBlock(
  _ProjectEditor editor,
  String path,
  ProjectIdentity identity,
) {
  _updateFile(editor, path, (source) {
    if (!source.contains('<!-- identity:start -->')) {
      return source;
    }
    final pattern = RegExp(
      r'<!-- identity:start -->[\s\S]*?<!-- identity:end -->',
    );
    final block =
        '''
<!-- identity:start -->
# ${identity.displayName}

- Package name: `${identity.packageName}`
- Display name: ${identity.displayName}
- Bundle id: `${identity.bundleId}`
<!-- identity:end -->''';
    return source.replaceFirst(pattern, block);
  }, 'project identity');
}

String _replaceProductBundleIdentifier(
  String source,
  String oldId,
  String newId,
) {
  final tests = RegExp(
    '^(.*PRODUCT_BUNDLE_IDENTIFIER = )${RegExp.escape(oldId)}(\\.RunnerTests;\\s*)\$',
    multiLine: true,
  );
  final app = RegExp(
    '^(.*PRODUCT_BUNDLE_IDENTIFIER = )${RegExp.escape(oldId)}(;\\s*)\$',
    multiLine: true,
  );
  final withTests = source.replaceAllMapped(tests, (match) {
    return '${match.group(1)}$newId${match.group(2)}';
  });
  return withTests.replaceAllMapped(app, (match) {
    return '${match.group(1)}$newId${match.group(2)}';
  });
}

String _replaceSet(
  String source,
  String key,
  String oldValue,
  String newValue,
) {
  final pattern = RegExp(
    '^(set\\($key ")${RegExp.escape(oldValue)}("\\))',
    multiLine: true,
  );
  return source.replaceAllMapped(pattern, (match) {
    return '${match.group(1)}$newValue${match.group(2)}';
  });
}

String _replaceRcValue(
  String source,
  String key,
  String oldValue,
  String newValue,
) {
  final pattern = RegExp('(VALUE "$key", ")${RegExp.escape(oldValue)}(")');
  return source.replaceAllMapped(pattern, (match) {
    return '${match.group(1)}$newValue${match.group(2)}';
  });
}

void _updateFile(
  _ProjectEditor editor,
  String relative,
  String Function(String source) transform,
  String summary,
) {
  final source = editor.read(relative);
  if (source == null) {
    return;
  }
  editor.update(relative, transform(source), summary);
}

class _ProjectEditor {
  _ProjectEditor(this.root);

  final Directory root;
  final Map<String, String> _buffers = {};
  final Map<String, List<String>> _summaries = {};
  final Set<String> _deletes = {};
  final Set<String> _created = {};

  String? read(String relative) {
    if (_buffers.containsKey(relative)) {
      return _buffers[relative];
    }
    final file = File(_join(root.path, relative));
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsStringSync();
  }

  void update(String relative, String next, String summary) {
    final current = read(relative);
    if (current == null || current == next) {
      return;
    }
    _buffers[relative] = next;
    _summaries.putIfAbsent(relative, () => []).add(summary);
  }

  void create(String relative, String contents, String summary) {
    _buffers[relative] = contents;
    _created.add(relative);
    _summaries.putIfAbsent(relative, () => []).add(summary);
  }

  void delete(String relative, String summary) {
    _deletes.add(relative);
    _summaries.putIfAbsent(relative, () => []).add(summary);
  }

  List<ProjectChange> get changes {
    final items = _summaries.entries.map((entry) {
      final action =
          _deletes.contains(entry.key) && !_buffers.containsKey(entry.key)
          ? 'delete'
          : _created.contains(entry.key)
          ? 'create'
          : 'update';
      return ProjectChange(
        path: entry.key,
        action: action,
        summary: entry.value.join(', '),
      );
    }).toList()..sort((a, b) => a.path.compareTo(b.path));
    return items;
  }

  void apply() {
    for (final entry in _buffers.entries) {
      final file = File(_join(root.path, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    for (final relative in _deletes) {
      if (_buffers.containsKey(relative)) {
        continue;
      }
      final file = File(_join(root.path, relative));
      if (!file.existsSync()) {
        continue;
      }
      final parent = file.parent;
      file.deleteSync();
      _pruneEmptyParents(parent);
    }
  }

  String relative(String absolute) {
    final rootPath = root.absolute.path;
    final path = File(absolute).absolute.path;
    final separator = Platform.pathSeparator;
    final prefix = rootPath.endsWith(separator)
        ? rootPath
        : '$rootPath$separator';
    final raw = path.startsWith(prefix) ? path.substring(prefix.length) : path;
    return raw.replaceAll('\\', '/');
  }

  void _pruneEmptyParents(Directory start) {
    var current = start;
    while (current.path.startsWith(root.path) && current.path != root.path) {
      final name = _baseName(current.path);
      if (name == 'kotlin' ||
          name == 'java' ||
          name == 'src' ||
          name == 'main') {
        return;
      }
      if (current.listSync().isNotEmpty) {
        return;
      }
      final parent = current.parent;
      current.deleteSync();
      current = parent;
    }
  }
}

Iterable<File> _listFiles(Directory directory) sync* {
  for (final entity in directory.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    if (_skippedDirectories.contains(name)) {
      continue;
    }
    if (entity is Directory) {
      yield* _listFiles(entity);
    } else if (entity is File) {
      yield entity;
    }
  }
}

Iterable<String> _projectFiles(Directory root, String suffix) sync* {
  for (final folder in ['ios', 'macos', 'linux', 'windows', 'android', 'web']) {
    final directory = Directory(_join(root.path, folder));
    if (!directory.existsSync()) {
      continue;
    }
    for (final file in _listFiles(directory)) {
      if (file.path.endsWith(suffix)) {
        yield _ProjectEditor(root).relative(file.path);
      }
    }
  }
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

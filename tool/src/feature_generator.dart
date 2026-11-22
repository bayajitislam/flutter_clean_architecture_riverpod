import 'dart:io';

import 'identity.dart';
import 'project_exception.dart';

class FeatureOutcome {
  const FeatureOutcome({required this.changes, required this.notes});

  final List<ProjectChange> changes;
  final List<String> notes;
}

/// Creates a feature module under `lib/features/<name>`.
///
/// Existing files are left untouched unless [force] is set. [dryRun] reports
/// the files and does not write them. Code generation runs only for a full
/// feature that was actually written.
Future<FeatureOutcome> generateFeature(
  Directory root, {
  required String name,
  bool presentationOnly = false,
  bool force = false,
  bool dryRun = false,
  bool runCodegen = true,
  bool finalize = true,
}) async {
  validatePackageName(name);
  final identity = ProjectIdentity.load(root);
  final names = FeatureNames(name);
  final files = presentationOnly
      ? _presentationFiles(identity.packageName, names)
      : _fullFeatureFiles(identity.packageName, names);

  final conflicts = <String>[];
  final changes = <ProjectChange>[];
  for (final entry in files.entries) {
    final file = File(_join(root.path, entry.key));
    if (file.existsSync() && !force) {
      conflicts.add(entry.key);
      continue;
    }
    changes.add(
      ProjectChange(
        path: entry.key,
        action: file.existsSync() ? 'update' : 'create',
        summary: 'feature ${names.feature}',
      ),
    );
  }
  if (conflicts.isNotEmpty) {
    throw ProjectToolException(
      'Feature files already exist. Pass --force to replace them:\n'
      '${conflicts.join('\n')}',
    );
  }

  final notes = <String>[
    'Register a GoRoute for ${names.pascalFeature}Screen in '
        'lib/core/routing/app_router.dart.',
  ];
  if (!dryRun) {
    for (final entry in files.entries) {
      final file = File(_join(root.path, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    if (runCodegen && !presentationOnly) {
      await _runBuildRunner(root);
      notes.add('Generated Freezed and JSON files with build_runner.');
    }
    if (finalize) {
      await _finalizeFeature(root, names.feature);
    }
  } else if (!presentationOnly) {
    notes.add(
      'Run dart run build_runner build --delete-conflicting-outputs '
      'after writing the feature.',
    );
  }

  changes.sort((a, b) => a.path.compareTo(b.path));
  return FeatureOutcome(changes: changes, notes: notes);
}

class FeatureNames {
  FeatureNames(this.feature) : typeSnake = singularize(feature);

  final String feature;
  final String typeSnake;

  String get pascalFeature => pascalCase(feature);

  String get pascalType => pascalCase(typeSnake);

  String get camelFeature => camelCase(feature);
}

String pascalCase(String snake) {
  return snake
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
}

String camelCase(String snake) {
  final parts = snake.split('_').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return snake;
  }
  return parts.first +
      parts
          .skip(1)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join();
}

String singularize(String snake) {
  final parts = snake.split('_');
  if (parts.isEmpty || parts.last.isEmpty) {
    return snake;
  }
  parts[parts.length - 1] = _singularWord(parts.last);
  return parts.join('_');
}

String _singularWord(String word) {
  if (word.endsWith('ies') && word.length > 3) {
    return '${word.substring(0, word.length - 3)}y';
  }
  const esEndings = ['ses', 'xes', 'ches', 'shes'];
  if (esEndings.any(word.endsWith) && word.length > 2) {
    return word.substring(0, word.length - 2);
  }
  if (word.endsWith('s') && !word.endsWith('ss') && word.length > 1) {
    return word.substring(0, word.length - 1);
  }
  return word;
}

Map<String, String> _fullFeatureFiles(String packageName, FeatureNames names) {
  final feature = names.feature;
  final type = names.typeSnake;
  final typeName = names.pascalType;
  final featureName = names.pascalFeature;
  final camel = names.camelFeature;
  final base = 'lib/features/$feature';
  final importBase = 'package:$packageName/features/$feature';
  return {
    '$base/domain/entities/$type.dart': _entity(typeName),
    '$base/domain/repositories/${type}_repository.dart': _repositoryContract(
      packageName,
      importBase,
      type,
      typeName,
    ),
    '$base/domain/usecases/load_$feature.dart': _useCase(
      packageName,
      importBase,
      type,
      typeName,
      featureName,
    ),
    '$base/data/models/${type}_model.dart': _model(importBase, type, typeName),
    '$base/data/datasources/${type}_remote_data_source.dart': _dataSource(
      importBase,
      type,
      typeName,
    ),
    '$base/data/repositories/${type}_repository_impl.dart': _repositoryImpl(
      packageName,
      importBase,
      type,
      typeName,
    ),
    '$base/data/providers/${type}_providers.dart': _dataProviders(
      importBase,
      type,
      typeName,
      camel,
    ),
    '$base/presentation/providers/${type}_providers.dart': _providers(
      packageName,
      importBase,
      feature,
      type,
      typeName,
      featureName,
      camel,
    ),
    '$base/presentation/screens/${feature}_screen.dart': _screen(
      packageName,
      importBase,
      type,
      typeName,
      featureName,
      camel,
    ),
    '$base/presentation/widgets/${type}_summary.dart': _summary(
      importBase,
      type,
      typeName,
    ),
    'test/unit/features/$feature/${type}_repository_impl_test.dart':
        _repositoryTest(packageName, importBase, feature, type, typeName),
    'test/widget/features/$feature/${feature}_screen_test.dart': _screenTest(
      packageName,
      importBase,
      feature,
      featureName,
    ),
  };
}

Map<String, String> _presentationFiles(String packageName, FeatureNames names) {
  final feature = names.feature;
  final featureName = names.pascalFeature;
  final camel = names.camelFeature;
  final base = 'lib/features/$feature/presentation';
  return {
    '$base/providers/${names.typeSnake}_providers.dart':
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${featureName}Controller extends Notifier<String> {
  @override
  String build() => '$featureName';
}

final ${camel}ControllerProvider =
    NotifierProvider<${featureName}Controller, String>(
      ${featureName}Controller.new,
    );
''',
    '$base/screens/${feature}_screen.dart':
        '''
import 'package:$packageName/features/$feature/presentation/providers/${names.typeSnake}_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${featureName}Screen extends ConsumerWidget {
  const ${featureName}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(${camel}ControllerProvider);
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}
''',
  };
}

String _entity(String typeName) {
  return '''
class $typeName {
  const $typeName({required this.id, required this.name});

  final String id;
  final String name;
}
''';
}

String _repositoryContract(
  String packageName,
  String importBase,
  String type,
  String typeName,
) {
  return '''
import 'package:$packageName/core/errors/result.dart';
import '$importBase/domain/entities/$type.dart';

abstract class ${typeName}Repository {
  Future<Result<List<$typeName>>> load();
}
''';
}

String _useCase(
  String packageName,
  String importBase,
  String type,
  String typeName,
  String featureName,
) {
  return '''
import 'package:$packageName/core/errors/result.dart';
import '$importBase/domain/entities/$type.dart';
import '$importBase/domain/repositories/${type}_repository.dart';

class Load$featureName {
  const Load$featureName(this._repository);

  final ${typeName}Repository _repository;

  Future<Result<List<$typeName>>> call() => _repository.load();
}
''';
}

String _model(String importBase, String type, String typeName) {
  return '''
import '$importBase/domain/entities/$type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '${type}_model.freezed.dart';
part '${type}_model.g.dart';

@freezed
abstract class ${typeName}Model with _\$${typeName}Model {
  const factory ${typeName}Model({
    required String id,
    required String name,
  }) = _${typeName}Model;

  factory ${typeName}Model.fromJson(Map<String, dynamic> json) =>
      _\$${typeName}ModelFromJson(json);
}

extension ${typeName}ModelX on ${typeName}Model {
  $typeName toEntity() => $typeName(id: id, name: name);
}
''';
}

String _dataSource(String importBase, String type, String typeName) {
  return '''
import '$importBase/data/models/${type}_model.dart';

abstract class ${typeName}RemoteDataSource {
  Future<List<${typeName}Model>> fetch();
}

class Unimplemented${typeName}RemoteDataSource
    implements ${typeName}RemoteDataSource {
  const Unimplemented${typeName}RemoteDataSource();

  @override
  Future<List<${typeName}Model>> fetch() {
    throw UnimplementedError(
      'Add an approved endpoint in the $type data source.',
    );
  }
}
''';
}

String _repositoryImpl(
  String packageName,
  String importBase,
  String type,
  String typeName,
) {
  return '''
import 'package:$packageName/core/errors/failure.dart';
import 'package:$packageName/core/errors/result.dart';
import '$importBase/data/datasources/${type}_remote_data_source.dart';
import '$importBase/data/models/${type}_model.dart';
import '$importBase/domain/entities/$type.dart';
import '$importBase/domain/repositories/${type}_repository.dart';

class ${typeName}RepositoryImpl implements ${typeName}Repository {
  const ${typeName}RepositoryImpl(this._remote);

  final ${typeName}RemoteDataSource _remote;

  @override
  Future<Result<List<$typeName>>> load() async {
    try {
      final models = await _remote.fetch();
      return Result.success(models.map((model) => model.toEntity()).toList());
    } on Object {
      return const Result.failure(UnknownFailure());
    }
  }
}
''';
}

String _dataProviders(
  String importBase,
  String type,
  String typeName,
  String camel,
) {
  return '''
import '$importBase/data/datasources/${type}_remote_data_source.dart';
import '$importBase/data/repositories/${type}_repository_impl.dart';
import '$importBase/domain/repositories/${type}_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${camel}RemoteDataSourceProvider = Provider<${typeName}RemoteDataSource>(
  (ref) => const Unimplemented${typeName}RemoteDataSource(),
);

final ${camel}RepositoryProvider = Provider<${typeName}Repository>((ref) {
  return ${typeName}RepositoryImpl(ref.watch(${camel}RemoteDataSourceProvider));
});
''';
}

String _providers(
  String packageName,
  String importBase,
  String feature,
  String type,
  String typeName,
  String featureName,
  String camel,
) {
  return '''
import 'package:$packageName/core/errors/failure.dart';
import 'package:$packageName/core/services/app_logger.dart';
import 'package:$packageName/core/state/request_gate.dart';
import '$importBase/data/providers/${type}_providers.dart';
import '$importBase/domain/entities/$type.dart';
import '$importBase/domain/usecases/load_$feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${featureName}State {
  const ${featureName}State({
    this.items = const [],
    this.failure,
    this.isLoading = false,
  });

  final List<$typeName> items;
  final Failure? failure;
  final bool isLoading;
}

final load${featureName}Provider = Provider<Load$featureName>((ref) {
  return Load$featureName(ref.watch(${camel}RepositoryProvider));
});

class ${featureName}Controller extends Notifier<${featureName}State> {
  final _requests = RequestGate();

  @override
  ${featureName}State build() {
    _requests.schedule(load);
    return const ${featureName}State(isLoading: true);
  }

  Future<void> load() {
    return _requests.run<$typeName>(
      mounted: () => ref.mounted,
      alreadyLoading:
          state.isLoading && state.failure == null && state.items.isEmpty,
      markLoading: () => state = const ${featureName}State(isLoading: true),
      request: () => ref.read(load${featureName}Provider).call(),
      onSuccess: (items) => state = ${featureName}State(items: items),
      onFailure: (failure) => state = ${featureName}State(failure: failure),
      onUnexpected: (error, stackTrace) {
        AppLogger.instance.error(
          'Loading $feature failed (\${error.runtimeType})',
          null,
          stackTrace,
        );
      },
    );
  }
}

final ${camel}ControllerProvider =
    NotifierProvider<${featureName}Controller, ${featureName}State>(
      ${featureName}Controller.new,
    );
''';
}

String _screen(
  String packageName,
  String importBase,
  String type,
  String typeName,
  String featureName,
  String camel,
) {
  return '''
import 'package:$packageName/core/widgets/app_error_view.dart';
import 'package:$packageName/core/widgets/app_loading.dart';
import '$importBase/presentation/providers/${type}_providers.dart';
import '$importBase/presentation/widgets/${type}_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${featureName}Screen extends ConsumerWidget {
  const ${featureName}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${camel}ControllerProvider);
    final body = state.isLoading
        ? const AppLoading()
        : state.failure != null
        ? AppErrorView(
            message: state.failure!.message,
            onRetry: () => ref.read(${camel}ControllerProvider.notifier).load(),
          )
        : ListView(
            children: [
              for (final item in state.items) ${typeName}Summary(item: item),
            ],
          );
    return Scaffold(appBar: AppBar(title: const Text('$featureName')), body: body);
  }
}
''';
}

String _summary(String importBase, String type, String typeName) {
  return '''
import '$importBase/domain/entities/$type.dart';
import 'package:flutter/material.dart';

class ${typeName}Summary extends StatelessWidget {
  const ${typeName}Summary({required this.item, super.key});

  final $typeName item;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(item.name));
  }
}
''';
}

String _repositoryTest(
  String packageName,
  String importBase,
  String feature,
  String type,
  String typeName,
) {
  return '''
import 'package:$packageName/core/errors/result.dart';
import '$importBase/data/datasources/${type}_remote_data_source.dart';
import '$importBase/data/models/${type}_model.dart';
import '$importBase/data/repositories/${type}_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake${typeName}Remote implements ${typeName}RemoteDataSource {
  @override
  Future<List<${typeName}Model>> fetch() async {
    return const [${typeName}Model(id: '1', name: '$typeName')];
  }
}

void main() {
  test('load maps remote models to entities', () async {
    final repository = ${typeName}RepositoryImpl(_Fake${typeName}Remote());

    final result = await repository.load();

    final names = result.fold(
      onSuccess: (value) => value.map((item) => item.name).toList(),
      onFailure: (_) => <String>[],
    );
    expect(names, ['$typeName']);
  });
}
''';
}

String _screenTest(
  String packageName,
  String importBase,
  String feature,
  String featureName,
) {
  return '''
import '$importBase/presentation/screens/${feature}_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('${featureName}Screen shows a failure until an endpoint exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ${featureName}Screen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('The request failed.'), findsOneWidget);
  });
}
''';
}

Future<void> _finalizeFeature(Directory root, String feature) async {
  final targets =
      [
            'lib/features/$feature',
            'test/unit/features/$feature',
            'test/widget/features/$feature',
          ]
          .where((target) => Directory(_join(root.path, target)).existsSync())
          .toList();
  for (final target in targets) {
    final fix = await Process.run('dart', [
      'fix',
      '--apply',
      target,
    ], workingDirectory: root.path);
    if (fix.exitCode != 0) {
      final output = '${fix.stdout}${fix.stderr}'.trim();
      throw ProjectToolException(
        output.isEmpty ? 'dart fix failed.' : 'dart fix failed:\n$output',
      );
    }
  }
  if (targets.isEmpty) {
    return;
  }
  final format = await Process.run('dart', [
    'format',
    ...targets,
  ], workingDirectory: root.path);
  if (format.exitCode != 0) {
    final output = '${format.stdout}${format.stderr}'.trim();
    throw ProjectToolException(
      output.isEmpty ? 'dart format failed.' : 'dart format failed:\n$output',
    );
  }
}

Future<void> _runBuildRunner(Directory root) async {
  final result = await Process.run('dart', [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ], workingDirectory: root.path);
  if (result.exitCode != 0) {
    final output = '${result.stdout}${result.stderr}'.trim();
    throw ProjectToolException(
      output.isEmpty ? 'build_runner failed.' : 'build_runner failed:\n$output',
    );
  }
}

String _join(String left, String right) {
  final separator = Platform.pathSeparator;
  final relative = right.replaceAll('/', separator);
  if (left.endsWith(separator)) {
    return '$left$relative';
  }
  return '$left$separator$relative';
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/cli_runner.dart';
import '../../../tool/src/feature_generator.dart';
import '../../../tool/src/project_exception.dart';
import '../../../tool/src/validate_project.dart';

void main() {
  group('generateFeature', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('awesome_feature_');
      _writeIdentity(root);
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('writes a full feature without calling the network', () async {
      final outcome = await generateFeature(
        root,
        name: 'products',
        runCodegen: false,
        finalize: false,
      );

      expect(
        outcome.changes.map((change) => change.path),
        contains('lib/features/products/domain/entities/product.dart'),
      );
      expect(
        _read(root, 'lib/features/products/data/models/product_model.dart'),
        contains('@freezed'),
      );
      expect(
        _read(
          root,
          'lib/features/products/data/datasources/product_remote_data_source.dart',
        ),
        contains('UnimplementedError'),
      );
      expect(
        _read(
          root,
          'lib/features/products/presentation/providers/product_providers.dart',
        ),
        allOf(
          contains('RequestGate'),
          contains('isLoading: true'),
          contains('schedule(load)'),
          isNot(contains('unawaited(load())')),
        ),
      );
      expect(outcome.notes.join('\n'), contains('app_router.dart'));
      expect(
        File('${root.path}/lib/core/routing/app_router.dart').existsSync(),
        isFalse,
      );
    });

    test('dry run writes nothing', () async {
      final outcome = await generateFeature(
        root,
        name: 'products',
        dryRun: true,
        runCodegen: false,
        finalize: false,
      );

      expect(outcome.changes, isNotEmpty);
      expect(
        File(
          '${root.path}/lib/features/products/domain/entities/product.dart',
        ).existsSync(),
        isFalse,
      );
    });

    test('refuses to overwrite without force', () async {
      await generateFeature(
        root,
        name: 'products',
        runCodegen: false,
        finalize: false,
      );

      expect(
        () => generateFeature(
          root,
          name: 'products',
          runCodegen: false,
          finalize: false,
        ),
        throwsA(isA<ProjectToolException>()),
      );
    });

    test('presentation-only skips data and domain', () async {
      await generateFeature(
        root,
        name: 'settings',
        presentationOnly: true,
        runCodegen: false,
        finalize: false,
      );

      expect(
        File(
          '${root.path}/lib/features/settings/presentation/screens/settings_screen.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory('${root.path}/lib/features/settings/domain').existsSync(),
        isFalse,
      );
    });

    test('singularize handles a trailing s and ies', () {
      expect(singularize('products'), 'product');
      expect(singularize('categories'), 'category');
      expect(singularize('boxes'), 'box');
      expect(pascalCase('user_profiles'), 'UserProfiles');
    });
  });

  test('feature create dry run returns success', () async {
    final root = Directory.systemTemp.createTempSync('awesome_cli_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    _writeIdentity(root);

    final code = await runCli([
      'feature',
      'create',
      'products',
      '--root',
      root.path,
      '--dry-run',
      '--skip-codegen',
    ]);

    expect(code, 0);
    expect(
      File(
        '${root.path}/lib/features/products/domain/entities/product.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('architectureIssues flags domain Flutter and allows provider wiring', () {
    final root = Directory.systemTemp.createTempSync('awesome_arch_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    _write(
      root,
      'lib/features/billing/domain/entities/bill.dart',
      "import 'package:material_ui/material_ui.dart';\n",
    );

    const packageName = 'flutter_clean_architecture_riverpod';
    expect(architectureIssues(root, packageName), isNotEmpty);

    root.deleteSync(recursive: true);
    root.createSync();
    _write(
      root,
      'lib/features/billing/presentation/providers/billing_providers.dart',
      "import 'package:$packageName/features/billing/data/providers/billing_providers.dart';\n",
    );
    _write(
      root,
      'lib/features/billing/presentation/screens/billing_screen.dart',
      "import 'package:$packageName/features/billing/data/datasources/billing_remote_data_source.dart';\n",
    );

    final issues = architectureIssues(root, packageName);
    expect(issues.any((issue) => issue.contains('providers')), isFalse);
    expect(
      issues.any((issue) => issue.contains('billing_screen.dart')),
      isTrue,
    );
  });
}

void _writeIdentity(Directory root) {
  _write(root, 'tool/project_identity.yaml', '''
package_name: "sample_app"
display_name: "Sample App"
bundle_id: "com.sample.sampleapp"
description: "Temporary feature fixture"
''');
}

void _write(Directory root, String path, String contents) {
  final file = File('${root.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

String _read(Directory root, String path) {
  return File('${root.path}/$path').readAsStringSync();
}

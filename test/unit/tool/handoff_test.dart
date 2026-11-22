import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/create_project.dart';
import '../../../tool/src/handoff.dart';
import '../../../tool/src/project_exception.dart';
import '../../../tool/src/validate_project.dart';

void main() {
  final source = Directory.current;

  test('create writes an independent application', () {
    final parent = Directory.systemTemp.createTempSync('awesome_shop_');
    addTearDown(() => parent.deleteSync(recursive: true));
    final output = Directory('${parent.path}/my_shop');

    createProject(
      source: source,
      output: output,
      packageName: 'my_shop',
      description: 'A shop for local orders.',
      brandColor: '#112233',
      platforms: const {'android', 'web'},
    );

    expect(_read(output, 'pubspec.yaml'), contains('name: my_shop'));
    expect(_read(output, 'pubspec.yaml'), contains('A shop for local orders.'));
    expect(_read(output, 'README.md'), contains('# My Shop'));
    expect(_read(output, 'README.md'), contains('A shop for local orders.'));
    expect(_read(output, 'README.md'), isNot(contains('CONTRIBUTING.md')));
    expect(_read(output, 'docs/architecture.md'), contains('lib/features'));
    expect(_read(output, 'docs/development.md'), contains('key.properties'));
    expect(_read(output, 'docs/updates.md'), contains('does not push changes'));
    expect(
      _read(output, 'tool/app_manifest.yaml'),
      contains('role: application'),
    );
    expect(
      _read(output, 'lib/core/theme/app_colors.dart'),
      contains('0xFF112233'),
    );
    expect(
      _read(output, 'env/dev.json.example'),
      contains('"APP_NAME": "My Shop"'),
    );
    expect(File(_join(output, 'CONTRIBUTING.md')).existsSync(), isFalse);
    expect(
      File(_join(output, '.github/PULL_REQUEST_TEMPLATE.md')).existsSync(),
      isFalse,
    );
    expect(
      Directory(_join(output, 'lib/features/showcase')).existsSync(),
      isFalse,
    );
    expect(Directory(_join(output, 'lib/features/auth')).existsSync(), isTrue);
    expect(Directory(_join(output, 'ios')).existsSync(), isFalse);
    expect(Directory(_join(output, 'android')).existsSync(), isTrue);
    expect(
      _read(output, 'lib/core/routing/app_router.dart'),
      isNot(contains('showcase')),
    );
    expect(checkProject(output), isEmpty);
    expect(_dartSources(output), isNot(contains('features/showcase/')));
  });

  test('showcase can be kept and sample auth can be removed', () {
    final parent = Directory.systemTemp.createTempSync('awesome_options_');
    addTearDown(() => parent.deleteSync(recursive: true));
    final withShowcase = Directory('${parent.path}/with_showcase');
    final noAuth = Directory('${parent.path}/no_auth');

    createProject(
      source: source,
      output: withShowcase,
      packageName: 'with_showcase',
      includeShowcase: true,
    );
    createProject(
      source: source,
      output: noAuth,
      packageName: 'no_auth',
      includeAuth: false,
    );

    expect(
      Directory(_join(withShowcase, 'lib/features/showcase')).existsSync(),
      isTrue,
    );
    expect(Directory(_join(noAuth, 'lib/features/auth')).existsSync(), isFalse);
    expect(
      _read(noAuth, 'lib/features/home/presentation/screens/home_screen.dart'),
      contains('Welcome'),
    );
    expect(
      _read(noAuth, 'lib/core/routing/app_router.dart'),
      isNot(contains('features/auth/')),
    );
    expect(checkProject(withShowcase), isEmpty);
    expect(checkProject(noAuth), isEmpty);
  });

  test('init rebrands a template checkout once', () {
    final checkout = Directory.systemTemp.createTempSync('awesome_template_');
    addTearDown(() => checkout.deleteSync(recursive: true));
    copyTemplate(source, checkout);

    final preview = initProject(
      root: checkout,
      options: const HandoffOptions(packageName: 'my_shop'),
      dryRun: true,
    );
    expect(preview, contains('Exclude the showcase feature.'));
    expect(File(_join(checkout, 'CONTRIBUTING.md')).existsSync(), isTrue);

    initProject(
      root: checkout,
      options: const HandoffOptions(packageName: 'my_shop'),
    );
    final readme = _read(checkout, 'README.md');
    expect(readme, contains('# My Shop'));
    expect(File(_join(checkout, 'CONTRIBUTING.md')).existsSync(), isFalse);
    expect(Directory(_join(checkout, '.fcar-backup')).existsSync(), isTrue);

    final again = initProject(
      root: checkout,
      options: const HandoffOptions(packageName: 'my_shop'),
    );
    expect(again.single, 'Already initialized as my_shop.');
    expect(_read(checkout, 'README.md'), readme);
    expect(checkProject(checkout), isEmpty);
  });

  test('a bad brand color is rejected before writing', () {
    final output = Directory('${Directory.systemTemp.path}/awesome_bad_color');
    expect(
      () => createProject(
        source: source,
        output: output,
        packageName: 'bad_color',
        brandColor: 'blue',
      ),
      throwsA(isA<ProjectToolException>()),
    );
    expect(output.existsSync(), isFalse);
  });
}

String _read(Directory root, String relative) {
  return File(_join(root, relative)).readAsStringSync();
}

String _join(Directory root, String relative) {
  return '${root.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
}

String _dartSources(Directory root) {
  final buffer = StringBuffer();
  for (final folder in ['lib']) {
    final directory = Directory(_join(root, folder));
    if (!directory.existsSync()) {
      continue;
    }
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        buffer.writeln(entity.readAsStringSync());
      }
    }
  }
  return buffer.toString();
}

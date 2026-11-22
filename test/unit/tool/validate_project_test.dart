import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/cli_runner.dart';
import '../../../tool/src/identity.dart';
import '../../../tool/src/validate_project.dart';

void main() {
  const identity = ProjectIdentity(
    packageName: 'sample_app',
    displayName: 'Sample App',
    bundleId: 'com.example.sample',
    description: 'Fixture',
  );

  test('a present platform with a missing id fails validation', () {
    final root = Directory.systemTemp.createTempSync('awesome_validate_');
    addTearDown(() => root.deleteSync(recursive: true));
    _write(
      root,
      'android/app/build.gradle.kts',
      'android { namespace = "com.example.sample" }\n',
    );

    final issues = platformIdentityIssues(root, identity);

    expect(
      issues,
      contains(
        'Android applicationId is missing in android/app/build.gradle.kts. '
        'Expected com.example.sample.',
      ),
    );
  });

  test('an incorrect bundle id is reported', () {
    final root = Directory.systemTemp.createTempSync('awesome_validate_');
    addTearDown(() => root.deleteSync(recursive: true));
    _write(
      root,
      'ios/Runner.xcodeproj/project.pbxproj',
      'PRODUCT_BUNDLE_IDENTIFIER = com.wrong.app;\n',
    );

    expect(
      platformIdentityIssues(root, identity),
      contains('iOS bundle id is com.wrong.app, expected com.example.sample.'),
    );
  });

  test('a missing platform file is required when the platform exists', () {
    final root = Directory.systemTemp.createTempSync('awesome_validate_');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/macos').createSync();

    expect(
      platformIdentityIssues(root, identity),
      contains('Missing macos/Runner/Configs/AppInfo.xcconfig.'),
    );
  });

  test('omitted platforms are optional', () {
    final root = Directory.systemTemp.createTempSync('awesome_validate_');
    addTearDown(() => root.deleteSync(recursive: true));

    expect(platformIdentityIssues(root, identity), isEmpty);
  });

  test('windows and linux identity must match when those folders exist', () {
    final root = Directory.systemTemp.createTempSync('awesome_validate_');
    addTearDown(() => root.deleteSync(recursive: true));
    _write(root, 'linux/CMakeLists.txt', 'project(runner LANGUAGES CXX)\n');
    _write(
      root,
      'windows/CMakeLists.txt',
      'project(other_app LANGUAGES CXX)\n',
    );

    final issues = platformIdentityIssues(root, identity);

    expect(
      issues.any((issue) => issue.startsWith('Linux application id')),
      isTrue,
    );
    expect(
      issues,
      contains('Windows project name is other_app, expected sample_app.'),
    );
  });

  test('validate returns 1 when required files are missing', () async {
    final root = Directory.systemTemp.createTempSync('awesome_validate_');
    addTearDown(() => root.deleteSync(recursive: true));
    _write(root, 'tool/project_identity.yaml', identity.toYaml());
    _write(root, 'pubspec.yaml', 'name: sample_app\n');

    expect(await runCli(['validate', '--root', root.path]), 1);
  });

  test('comments and string literals are not architecture imports', () {
    final root = Directory.systemTemp.createTempSync('awesome_arch_');
    addTearDown(() => root.deleteSync(recursive: true));
    _write(root, 'lib/features/billing/domain/entities/bill.dart', '''
// import "package:flutter/material.dart";
/// import 'package:dio/dio.dart';
const example = "import 'package:flutter/widgets.dart';";
import '../../billing/domain/entities/other.dart';
''');

    expect(architectureIssues(root, 'sample_app'), isEmpty);
  });

  test('relative exports and double-quoted imports are violations', () {
    final root = Directory.systemTemp.createTempSync('awesome_arch_');
    addTearDown(() => root.deleteSync(recursive: true));
    _write(
      root,
      'lib/features/billing/domain/entities/bill.dart',
      'import "package:flutter/material.dart";\n',
    );
    _write(
      root,
      'lib/features/home/presentation/screens/home_screen.dart',
      "export '../../../billing/data/bill_api.dart';\n",
    );
    _write(
      root,
      'lib/features/billing/presentation/providers/billing_providers.dart',
      "import 'package:sample_app/features/billing/data/providers/billing_providers.dart';\n",
    );

    final issues = architectureIssues(root, 'sample_app');

    expect(issues.any((issue) => issue.contains('bill.dart imports')), isTrue);
    expect(
      issues.any((issue) => issue.contains('home_screen.dart imports')),
      isTrue,
    );
    expect(
      issues.any((issue) => issue.contains('billing_providers.dart')),
      isFalse,
    );
  });
}

void _write(Directory root, String path, String contents) {
  final file = File('${root.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

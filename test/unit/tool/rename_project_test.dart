import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/create_project.dart';
import '../../../tool/src/identity.dart';
import '../../../tool/src/project_exception.dart';
import '../../../tool/src/rename_project.dart';
import '../../../tool/src/validate_project.dart';

void main() {
  group('renameProject', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('awesome_rename_');
      _writeFixture(root);
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('updates structured fields and leaves signing and URL schemes', () {
      const renamed = 'new_app';
      final outcome = renameProject(
        root,
        request: const RenameRequest(
          packageName: renamed,
          displayName: 'New App',
          bundleId: 'com.client.newapp',
        ),
      );

      expect(outcome.warnings, isNotEmpty);
      expect(_read(root, 'pubspec.yaml'), contains('name: $renamed'));
      final mainSource = _read(root, 'lib/main.dart');
      final flutterAt = mainSource.indexOf('package:flutter/');
      final packageAt = mainSource.indexOf('package:$renamed/');
      expect(flutterAt, isNonNegative);
      expect(packageAt, isNonNegative);
      expect(flutterAt, lessThan(packageAt));
      final gradle = _read(root, 'android/app/build.gradle.kts');
      expect(gradle, contains('namespace = "com.client.newapp"'));
      expect(gradle, contains('applicationId = "com.client.newapp"'));
      expect(
        gradle,
        contains('signingConfig = signingConfigs.getByName("debug")'),
      );
      expect(gradle, contains('storeFile = file("upload-keystore.jks")'));
      expect(
        _read(root, 'android/app/src/main/AndroidManifest.xml'),
        contains('android:label="New App"'),
      );
      expect(
        _read(
          root,
          'android/app/src/main/kotlin/com/client/newapp/MainActivity.kt',
        ),
        contains('package com.client.newapp'),
      );
      expect(
        File(
          _path(
            root,
            'android/app/src/main/kotlin/com/acme/oldapp/MainActivity.kt',
          ),
        ).existsSync(),
        isFalse,
      );
      final plist = _read(root, 'ios/Runner/Info.plist');
      expect(plist, contains('<string>New App</string>'));
      expect(plist, contains('<string>com.acme.oldapp</string>'));
      final project = _read(root, 'ios/Runner.xcodeproj/project.pbxproj');
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.client.newapp;'),
      );
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.client.newapp.RunnerTests;'),
      );
      expect(project, contains('$renamed.app'));
      expect(project, contains('marker old_app stays'));
      final config = _read(root, 'macos/Runner/Configs/AppInfo.xcconfig');
      expect(config, contains('PRODUCT_BUNDLE_IDENTIFIER = com.client.newapp'));
      expect(config, contains('PRODUCT_NAME = $renamed'));
      final cmake = _read(root, 'linux/CMakeLists.txt');
      expect(cmake, contains('set(APPLICATION_ID "com.client.newapp")'));
      expect(cmake, contains('set(BINARY_NAME "$renamed")'));
      expect(
        _read(root, 'linux/runner/my_application.cc'),
        contains('gtk_window_set_title(window, "New App")'),
      );
      final resources = _read(root, 'windows/runner/Runner.rc');
      expect(resources, contains('VALUE "ProductName", "New App"'));
      expect(resources, contains('VALUE "OriginalFilename", "$renamed.exe"'));
      expect(_read(root, 'web/index.html'), contains('<title>New App</title>'));
      expect(_read(root, 'web/manifest.json'), contains('"name": "New App"'));
      expect(
        _read(root, 'android/app/google-services.json'),
        contains('com.acme.oldapp'),
      );
      expect(_read(root, 'README.md'), contains('Package name: `$renamed`'));
      expect(ProjectIdentity.load(root).bundleId, 'com.client.newapp');
    });

    test('dry run does not write files', () {
      final before = _read(root, 'pubspec.yaml');

      renameProject(
        root,
        request: const RenameRequest(packageName: 'new_app'),
        dryRun: true,
      );

      expect(_read(root, 'pubspec.yaml'), before);
    });

    test('rejects a package name that is not snake_case', () {
      expect(
        () => renameProject(
          root,
          request: const RenameRequest(packageName: 'NewApp'),
        ),
        throwsA(isA<ProjectToolException>()),
      );
    });
  });

  group('createProject', () {
    late Directory source;
    late Directory parent;

    setUp(() {
      source = Directory.systemTemp.createTempSync('awesome_source_');
      parent = Directory.systemTemp.createTempSync('awesome_output_');
      _writeFixture(source);
      Directory(_path(source, '.git')).createSync();
      File(_path(source, '.git/config')).writeAsStringSync('source-git');
      Directory(_path(source, 'build')).createSync();
      File(_path(source, 'build/app.so')).writeAsStringSync('binary');
    });

    tearDown(() {
      if (source.existsSync()) {
        source.deleteSync(recursive: true);
      }
      if (parent.existsSync()) {
        parent.deleteSync(recursive: true);
      }
    });

    test('copies the template and renames only the copy', () {
      final destination = Directory(_path(parent, 'client_app'));

      createProject(
        source: source,
        output: destination,
        packageName: 'client_app',
      );

      expect(_read(source, 'pubspec.yaml'), contains('name: old_app'));
      expect(_read(destination, 'pubspec.yaml'), contains('name: client_app'));
      expect(File(_path(destination, '.git/config')).existsSync(), isFalse);
      expect(File(_path(destination, 'build/app.so')).existsSync(), isFalse);
      expect(
        _read(destination, 'android/app/google-services.json'),
        contains('com.acme.oldapp'),
      );
    });

    test('leaves local secrets and machine paths out of the copy', () {
      final destination = Directory(_path(parent, 'clean_app'));
      _write(source, 'android/local.properties', 'sdk.dir=/Users/someone/sdk');
      _write(
        source,
        'ios/Flutter/Generated.xcconfig',
        'FLUTTER_ROOT=/Users/someone/flutter',
      );
      _write(
        source,
        'ios/Flutter/flutter_export_environment.sh',
        'export FLUTTER_ROOT=/Users/someone/flutter',
      );
      _write(source, 'android/key.properties', 'storePassword=secret');
      _write(
        source,
        'env/dev.json',
        '{"API_BASE_URL":"https://private.example"}',
      );
      _write(source, 'env/dev.json.example', '{"API_BASE_URL":""}');
      _write(source, 'flutter_01.log', 'crash');

      createProject(
        source: source,
        output: destination,
        packageName: 'clean_app',
      );

      expect(
        File(_path(destination, 'android/local.properties')).existsSync(),
        isFalse,
      );
      expect(
        File(_path(destination, 'ios/Flutter/Generated.xcconfig')).existsSync(),
        isFalse,
      );
      expect(
        File(
          _path(destination, 'ios/Flutter/flutter_export_environment.sh'),
        ).existsSync(),
        isFalse,
      );
      expect(
        File(_path(destination, 'android/key.properties')).existsSync(),
        isFalse,
      );
      expect(File(_path(destination, 'env/dev.json')).existsSync(), isFalse);
      expect(File(_path(destination, 'flutter_01.log')).existsSync(), isFalse);
      expect(
        _read(destination, 'env/dev.json.example'),
        contains('API_BASE_URL'),
      );
    });
  });

  test('the template identity matches the platforms and layout', () {
    expect(checkProject(Directory.current), isEmpty);
  });
}

void _writeFixture(Directory root) {
  const packageName = 'old_app';
  const displayName = 'Old App';
  const bundleId = 'com.acme.oldapp';
  _write(root, 'tool/project_identity.yaml', '''
package_name: "$packageName"
display_name: "$displayName"
bundle_id: "$bundleId"
description: "Fixture"
''');
  _write(root, 'pubspec.yaml', 'name: $packageName\n');
  _write(
    root,
    'lib/main.dart',
    "import 'package:$packageName/app.dart';\n"
        "import 'package:flutter/widgets.dart';\n",
  );
  _write(root, 'android/app/build.gradle.kts', '''
android {
    namespace = "$bundleId"
    defaultConfig {
        applicationId = "$bundleId"
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            storeFile = file("upload-keystore.jks")
        }
    }
}
''');
  _write(
    root,
    'android/app/src/main/AndroidManifest.xml',
    '<application android:label="$displayName"></application>\n',
  );
  _write(
    root,
    'android/app/src/main/kotlin/com/acme/oldapp/MainActivity.kt',
    'package $bundleId\n\nclass MainActivity\n',
  );
  _write(
    root,
    'android/app/google-services.json',
    '{"package_name":"$bundleId"}\n',
  );
  _write(root, 'ios/Runner/Info.plist', '''
<key>CFBundleDisplayName</key>
<string>$displayName</string>
<key>CFBundleURLSchemes</key>
<array>
  <string>$bundleId</string>
</array>
''');
  _write(root, 'ios/Runner.xcodeproj/project.pbxproj', '''
PRODUCT_BUNDLE_IDENTIFIER = $bundleId;
PRODUCT_BUNDLE_IDENTIFIER = $bundleId.RunnerTests;
TEST_HOST = "\$(BUILT_PRODUCTS_DIR)/$packageName.app/\$(BUNDLE_EXECUTABLE_FOLDER_PATH)/$packageName";
path = "$packageName.app";
/* marker old_app stays */
''');
  _write(root, 'macos/Runner/Configs/AppInfo.xcconfig', '''
PRODUCT_NAME = $packageName
PRODUCT_BUNDLE_IDENTIFIER = $bundleId
''');
  _write(root, 'linux/CMakeLists.txt', '''
set(BINARY_NAME "$packageName")
set(APPLICATION_ID "$bundleId")
''');
  _write(
    root,
    'linux/runner/my_application.cc',
    'gtk_window_set_title(window, "$displayName");\n',
  );
  _write(root, 'windows/CMakeLists.txt', '''
project($packageName LANGUAGES CXX)
set(BINARY_NAME "$packageName")
''');
  _write(root, 'windows/runner/Runner.rc', '''
VALUE "FileDescription", "$displayName" "\\0"
VALUE "ProductName", "$displayName" "\\0"
VALUE "InternalName", "$packageName" "\\0"
VALUE "OriginalFilename", "$packageName.exe" "\\0"
''');
  _write(root, 'web/index.html', '''
<title>$displayName</title>
<meta name="apple-mobile-web-app-title" content="$displayName">
''');
  _write(root, 'web/manifest.json', '''
{
  "name": "$displayName",
  "short_name": "$displayName"
}
''');
  final identity =
      '''
<!-- identity:start -->
# $displayName

- Package name: `$packageName`
- Display name: $displayName
- Bundle id: `$bundleId`
<!-- identity:end -->
''';
  _write(root, 'README.md', identity);
  _write(root, 'AGENTS.md', identity);
}

void _write(Directory root, String relative, String contents) {
  final file = File(_path(root, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

String _read(Directory root, String relative) {
  return File(_path(root, relative)).readAsStringSync();
}

String _path(Directory root, String relative) {
  return '${root.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
}

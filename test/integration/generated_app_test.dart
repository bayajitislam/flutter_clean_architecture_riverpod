import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/create_project.dart';

void main() {
  test(
    'a generated application formats, analyzes, tests, and builds web',
    () async {
      final parent = Directory.systemTemp.createTempSync('awesome_built_');
      addTearDown(() => parent.deleteSync(recursive: true));
      final output = Directory('${parent.path}/my_shop');

      createProject(
        source: Directory.current,
        output: output,
        packageName: 'my_shop',
        platforms: const {'android', 'web'},
      );

      await _run(output, 'dart', [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        '.',
      ]);
      await _run(output, 'flutter', ['pub', 'get']);
      await _run(output, 'flutter', ['analyze']);
      await _run(output, 'flutter', ['test']);
      await _run(output, 'dart', [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]);
      await _run(output, 'flutter', ['build', 'web']);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _run(Directory root, String executable, List<String> args) async {
  final result = await Process.run(
    executable,
    args,
    workingDirectory: root.path,
  );
  if (result.exitCode != 0) {
    fail(
      '$executable ${args.join(' ')} failed.\n${result.stdout}\n${result.stderr}',
    );
  }
}

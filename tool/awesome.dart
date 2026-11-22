import 'dart:io';

import 'src/cli_runner.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}

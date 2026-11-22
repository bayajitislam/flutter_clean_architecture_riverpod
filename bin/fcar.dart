import 'dart:io';

import '../tool/src/cli_runner.dart';

Future<void> main(List<String> args) async {
  exit(await runCli(args));
}

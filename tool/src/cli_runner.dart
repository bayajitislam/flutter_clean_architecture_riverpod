import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'create_project.dart';
import 'feature_generator.dart';
import 'handoff.dart';
import 'identity.dart';
import 'project_exception.dart';
import 'rename_project.dart';
import 'validate_project.dart';

// The CLI is a terminal tool. Logging goes to stdout and stderr on purpose.
// ignore_for_file: avoid_print

Future<int> runCli(List<String> args) async {
  final runner =
      CommandRunner<int>(
          'fcar',
          'Create, rename, generate features, and validate a Flutter Clean Architecture Riverpod project.',
        )
        ..addCommand(CreateCommand())
        ..addCommand(InitCommand())
        ..addCommand(RenameCommand())
        ..addCommand(FeatureCommand())
        ..addCommand(ValidateCommand());
  try {
    return await runner.run(args) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    return 64;
  } on ProjectToolException catch (error) {
    stderr.writeln(error.message);
    return 1;
  }
}

class CreateCommand extends Command<int> {
  CreateCommand() {
    argParser
      ..addOption(
        'name',
        help: 'Dart package name. You can also pass it as an argument.',
      )
      ..addOption('display-name', help: 'Name shown on the device.')
      ..addOption(
        'bundle-id',
        help: 'Android application id and Apple bundle id.',
      )
      ..addOption('output', help: 'Directory for the new project.')
      ..addOption('description', help: 'Sentence stored in pubspec.yaml.')
      ..addOption(
        'brand-color',
        help: 'Six-digit brand color, such as #1565C0.',
      )
      ..addOption(
        'platforms',
        help:
            'Comma-separated platforms. Defaults to android, ios, web, macos, linux, and windows.',
      )
      ..addFlag(
        'showcase',
        negatable: false,
        help: 'Copy the layout showcase. Omitted by default.',
      )
      ..addFlag(
        'no-auth',
        negatable: false,
        help: 'Leave out the sample sign-in feature.',
      )
      ..addOption(
        'root',
        help: 'Template root. Defaults to the current directory.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print the plan without copying.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Replace a non-empty output directory.',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description =>
      'Create an independent application from this starter kit.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final root = Directory(
      (results['root'] as String?) ?? Directory.current.path,
    );
    final packageName = _requireName(results, usage);
    final output = Directory(
      (results['output'] as String?) ?? _join(root.parent.path, packageName),
    );
    final created = createProject(
      source: root,
      output: output,
      packageName: packageName,
      displayName: results['display-name'] as String?,
      bundleId: results['bundle-id'] as String?,
      description: results['description'] as String?,
      brandColor: results['brand-color'] as String?,
      platforms: parsePlatforms(results['platforms'] as String?),
      includeShowcase: results['showcase'] as bool,
      includeAuth: !(results['no-auth'] as bool),
      dryRun: results['dry-run'] as bool,
      force: results['force'] as bool,
    );
    final prefix = created.copied ? 'Created' : 'Would create';
    stdout.writeln('$prefix ${output.path}');
    _printOutcome(created.outcome);
    for (final note in created.notes) {
      stdout.writeln(note);
    }
    return 0;
  }
}

class InitCommand extends Command<int> {
  InitCommand() {
    argParser
      ..addOption(
        'name',
        help: 'Dart package name. You can also pass it as an argument.',
      )
      ..addOption('display-name', help: 'Name shown on the device.')
      ..addOption(
        'bundle-id',
        help: 'Android application id and Apple bundle id.',
      )
      ..addOption('description', help: 'Sentence stored in pubspec.yaml.')
      ..addOption(
        'brand-color',
        help: 'Six-digit brand color, such as #1565C0.',
      )
      ..addOption(
        'platforms',
        help:
            'Comma-separated platforms. Defaults to android, ios, web, macos, linux, and windows.',
      )
      ..addFlag(
        'showcase',
        negatable: false,
        help: 'Keep the layout showcase. Omitted by default.',
      )
      ..addFlag(
        'no-auth',
        negatable: false,
        help: 'Remove the sample sign-in feature.',
      )
      ..addOption(
        'root',
        help: 'Checkout to initialize. Defaults to the current directory.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print the plan without writing.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Rename an application that was already initialized.',
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Turn a GitHub template checkout into this application.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final root = Directory(
      (results['root'] as String?) ?? Directory.current.path,
    );
    final packageName = _requireName(results, usage);
    final notes = initProject(
      root: root,
      options: HandoffOptions(
        packageName: packageName,
        displayName: results['display-name'] as String?,
        bundleId: results['bundle-id'] as String?,
        description: results['description'] as String?,
        brandColor: results['brand-color'] as String?,
        platforms: parsePlatforms(results['platforms'] as String?),
        includeShowcase: results['showcase'] as bool,
        includeAuth: !(results['no-auth'] as bool),
      ),
      dryRun: results['dry-run'] as bool,
      force: results['force'] as bool,
    );
    stdout.writeln(
      results['dry-run'] as bool ? 'Would initialize' : 'Initialized',
    );
    for (final note in notes) {
      stdout.writeln(note);
    }
    return 0;
  }
}

class RenameCommand extends Command<int> {
  RenameCommand() {
    argParser
      ..addOption(
        'name',
        help: 'New Dart package name. You can also pass it as an argument.',
      )
      ..addOption('display-name', help: 'New name shown on the device.')
      ..addOption(
        'bundle-id',
        help: 'New Android application id and Apple bundle id.',
      )
      ..addOption(
        'root',
        help: 'Project root. Defaults to the current directory.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print the plan without writing.',
      );
  }

  @override
  String get name => 'rename';

  @override
  String get description =>
      'Rename this project without a global text replace.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final root = Directory(
      (results['root'] as String?) ?? Directory.current.path,
    );
    final dryRun = results['dry-run'] as bool;
    final outcome = renameProject(
      root,
      request: RenameRequest(
        packageName: _optionalName(results),
        displayName: results['display-name'] as String?,
        bundleId: results['bundle-id'] as String?,
      ),
      dryRun: dryRun,
    );
    stdout.writeln(dryRun ? 'Rename (dry run)' : 'Renamed project');
    _printOutcome(outcome);
    return 0;
  }
}

class FeatureCommand extends Command<int> {
  FeatureCommand() {
    addSubcommand(FeatureCreateCommand());
  }

  @override
  String get name => 'feature';

  @override
  String get description => 'Generate feature modules.';

  @override
  Future<int> run() async {
    throw UsageException('Pass a feature command.', usage);
  }
}

class FeatureCreateCommand extends Command<int> {
  FeatureCreateCommand() {
    argParser
      ..addOption(
        'name',
        help: 'Feature folder name. You can also pass it as an argument.',
      )
      ..addOption(
        'root',
        help: 'Project root. Defaults to the current directory.',
      )
      ..addFlag(
        'presentation-only',
        negatable: false,
        help: 'Generate the screen and controller without data or domain.',
      )
      ..addFlag(
        'skip-codegen',
        negatable: false,
        help: 'Do not run build_runner after writing files.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print the files without writing them.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Replace feature files that already exist.',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description =>
      'Add a feature with data, domain, presentation, and tests.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final root = Directory(
      (results['root'] as String?) ?? Directory.current.path,
    );
    final dryRun = results['dry-run'] as bool;
    final presentationOnly = results['presentation-only'] as bool;
    final outcome = await generateFeature(
      root,
      name: _requireName(results, usage),
      presentationOnly: presentationOnly,
      force: results['force'] as bool,
      dryRun: dryRun,
      runCodegen: !presentationOnly && !(results['skip-codegen'] as bool),
    );
    stdout.writeln(dryRun ? 'Feature (dry run)' : 'Created feature');
    if (outcome.changes.isEmpty) {
      stdout.writeln('No file changes.');
    } else {
      for (final change in outcome.changes) {
        stdout.writeln('${change.action} ${change.path} (${change.summary})');
      }
    }
    for (final note in outcome.notes) {
      stdout.writeln('note: $note');
    }
    return 0;
  }
}

class ValidateCommand extends Command<int> {
  ValidateCommand() {
    argParser
      ..addOption(
        'root',
        help: 'Project root. Defaults to the current directory.',
      )
      ..addFlag('analyze', negatable: false, help: 'Also run flutter analyze.')
      ..addFlag(
        'dry-run',
        negatable: false,
        help: 'Print checks without running flutter analyze.',
      );
  }

  @override
  String get name => 'validate';

  @override
  String get description => 'Check architecture, identity, and project layout.';

  @override
  Future<int> run() async {
    final results = argResults!;
    final root = Directory(
      (results['root'] as String?) ?? Directory.current.path,
    );
    final report = await validateProject(
      root,
      analyze: results['analyze'] as bool,
      dryRun: results['dry-run'] as bool,
    );
    if (report.isValid) {
      stdout.writeln('Project layout and identity match.');
      return 0;
    }
    stdout.writeln('Validation failed:');
    for (final issue in report.issues) {
      stdout.writeln('- $issue');
    }
    return 1;
  }
}

String? _optionalName(ArgResults results) {
  final option = results['name'] as String?;
  if (results.rest.length > 1) {
    throw ProjectToolException('Pass one name.');
  }
  final positional = results.rest.isEmpty ? null : results.rest.single;
  if (option != null && positional != null && option != positional) {
    throw ProjectToolException('The name argument and --name do not match.');
  }
  return positional ?? option;
}

String _requireName(ArgResults results, String usage) {
  final name = _optionalName(results);
  if (name != null) {
    return name;
  }
  if (stdin.hasTerminal) {
    stdout.write('Dart package name: ');
    final entered = stdin.readLineSync()?.trim();
    if (entered != null && entered.isNotEmpty) {
      return entered;
    }
  }
  throw UsageException('Pass a name.', usage);
}

void _printOutcome(RenameOutcome outcome) {
  if (outcome.changes.isEmpty) {
    stdout.writeln('No file changes.');
  } else {
    for (final change in outcome.changes) {
      stdout.writeln('${change.action} ${change.path} (${change.summary})');
    }
  }
  for (final warning in outcome.warnings) {
    stdout.writeln('warning: $warning');
  }
}

String _join(String left, String right) {
  final separator = Platform.pathSeparator;
  if (left.endsWith(separator)) {
    return '$left$right';
  }
  return '$left$separator$right';
}

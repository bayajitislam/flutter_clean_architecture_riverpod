import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/services/app_logger.dart';
import 'package:flutter_devlog/flutter_devlog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final records = <LogRecord>[];

  setUp(() {
    records.clear();
    DevLog.reset();
    DevLog.onLog = records.add;
  });

  tearDown(DevLog.reset);

  test('debug info warning and error use package levels', () {
    AppLogger.instance
      ..debug('detail')
      ..info('ready')
      ..warning('slow')
      ..error('failed', StateError('x'), StackTrace.current);

    expect(records.map((record) => record.level.name), [
      'DEBUG',
      'INFO',
      'WARN',
      'ERROR',
    ]);
    expect(records.first.level.priority, LogPriority.ui);
    expect(records[2].level, LogLevel.warn);
    expect(records.last.error, isA<StateError>());
  });

  test('staging keeps warnings and drops debug detail', () {
    AppLogger.instance.configure(AppFlavor.staging);
    DevLog.onLog = records.add;

    AppLogger.instance.debug('detail');
    AppLogger.instance.warning('retry');

    expect(records.map((record) => record.message), ['retry']);
  });

  test('production records nothing', () {
    AppLogger.instance.configure(AppFlavor.prod);
    DevLog.onLog = records.add;

    AppLogger.instance.error('secret');

    expect(records, isEmpty);
  });
}

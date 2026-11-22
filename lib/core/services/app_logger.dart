import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_devlog/flutter_devlog.dart';

/// The only logger application code should call.
///
/// `flutter_devlog` has no `debug` method. [debug] uses [DevLog.log] with a
/// `DEBUG` level at [LogPriority.ui], the package's lowest priority. [warning]
/// calls [DevLog.warn]. [info], [api], and [error] call the matching methods.
///
/// Do not pass passwords, tokens, API keys, or the `Authorization` header.
class AppLogger {
  const AppLogger();

  static const instance = AppLogger();

  /// Development detail. Filtered out when the minimum priority is above `ui`.
  static const debugLevel = LogLevel('DEBUG', LogColor.grey, LogPriority.ui);

  /// Chooses how much [DevLog] prints for this flavor.
  ///
  /// Development shows every level. Staging keeps warnings and errors.
  /// Production turns the logger off. Release builds are silent either way,
  /// because `flutter_devlog` removes its calls when asserts are disabled.
  void configure(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.dev:
        DevLog.configure(
          enabled: true,
          minPriority: LogPriority.ui,
          useColors: true,
        );
      case AppFlavor.staging:
        DevLog.configure(
          enabled: true,
          minPriority: LogPriority.warn,
          useColors: false,
        );
      case AppFlavor.prod:
        DevLog.configure(
          enabled: false,
          minPriority: LogPriority.error,
          useColors: false,
        );
    }
  }

  void debug(String message) => DevLog.log(message, level: debugLevel);

  void info(String message) => DevLog.info(message);

  void warning(String message) => DevLog.warn(message);

  void api(String message) => DevLog.api(message);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    DevLog.error(message, error: error, stackTrace: stackTrace);
  }
}

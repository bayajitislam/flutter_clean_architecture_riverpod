import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build flavor selected with `--dart-define-from-file`.
enum AppFlavor { dev, staging, prod }

/// Compile-time environment values.
///
/// Secrets stay in an untracked JSON file and are passed with
/// `--dart-define-from-file`. They are not bundled as assets.
class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.appName,
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String appName;

  static const flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );
  static const apiBaseUrlFromEnvironment = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const appNameFromEnvironment = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Flutter Clean Architecture Riverpod',
  );

  factory AppEnv.fromEnvironment() {
    final env = AppEnv(
      flavor: parseAppFlavor(flavorName),
      apiBaseUrl: apiBaseUrlFromEnvironment,
      appName: appNameFromEnvironment,
    );
    env.validate();
    return env;
  }

  /// True when a real API base URL was provided for this build.
  bool get hasApi => apiBaseUrl.trim().isNotEmpty;

  /// Rejects an unknown flavor and a staging or production build with no API.
  ///
  /// Development may omit `API_BASE_URL` and use the fake auth source.
  void validate() {
    if (flavor != AppFlavor.dev && !hasApi) {
      throw StateError(
        '${flavor.name} builds require API_BASE_URL. '
        'Pass it with --dart-define-from-file.',
      );
    }
  }
}

/// Parses `dev`, `staging`, or `prod`.
AppFlavor parseAppFlavor(String raw) {
  return switch (raw) {
    'dev' => AppFlavor.dev,
    'staging' => AppFlavor.staging,
    'prod' => AppFlavor.prod,
    _ => throw StateError('FLAVOR must be dev, staging, or prod.'),
  };
}

/// The environment for this process. Override it in tests and `main`.
final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromEnvironment());

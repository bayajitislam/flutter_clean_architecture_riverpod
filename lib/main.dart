import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_clean_architecture_riverpod/app.dart';
import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/services/app_logger.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/theme_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        AppLogger.instance.error(
          details.exceptionAsString(),
          details.exception,
          details.stack,
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.instance.error('Uncaught platform error', error, stack);
        return true;
      };

      final preferences = await SharedPreferences.getInstance();
      final env = AppEnv.fromEnvironment();
      AppLogger.instance.configure(env.flavor);
      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            appEnvProvider.overrideWithValue(env),
          ],
          child: const App(),
        ),
      );
    },
    (error, stack) {
      AppLogger.instance.error('Uncaught zone error', error, stack);
    },
  );
}

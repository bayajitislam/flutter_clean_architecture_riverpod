import 'package:flutter_clean_architecture_riverpod/app.dart';
import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/extensions/context_extensions.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_theme_extensions.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/theme_mode_controller.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the app follows light, dark, and system appearance', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appEnvProvider.overrideWithValue(
          const AppEnv(flavor: AppFlavor.dev, apiBaseUrl: '', appName: 'Test'),
        ),
        authControllerProvider.overrideWith(_SignedOutAuth.new),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();

    expect(_brightness(tester), Brightness.light);
    expect(_status(tester).success, isNot(_status(tester).warning));

    await container
        .read(themeModeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await container
        .read(themeModeControllerProvider.notifier)
        .setThemeMode(ThemeMode.system);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(preferences.getString('theme_mode'), 'system');
  });
}

Brightness _brightness(WidgetTester tester) {
  return Theme.of(tester.element(find.text('Sign in'))).brightness;
}

AppStatusColors _status(WidgetTester tester) {
  return tester.element(find.text('Sign in')).statusColors;
}

class _SignedOutAuth extends AuthController {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}

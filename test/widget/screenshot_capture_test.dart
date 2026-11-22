@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_clean_architecture_riverpod/app.dart';
import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/theme_mode_controller.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/auth_strings.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regenerates README screenshots under docs/screenshots/.
///
/// Excluded from CI (`--exclude-tags screenshots`) because goldens are
/// platform-sensitive. Regenerate locally with:
///
/// ```bash
/// flutter test test/widget/screenshot_capture_test.dart --update-goldens
/// ```
void main() {
  setUpAll(_loadFonts);

  testWidgets('login light', (tester) async {
    await _configureView(tester);
    await _pump(tester, themeMode: 'light', auth: _SignedOutAuth.new);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/login-light.png'),
    );
  });

  testWidgets('login dark', (tester) async {
    await _configureView(tester);
    await _pump(tester, themeMode: 'dark', auth: _SignedOutAuth.new);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/login-dark.png'),
    );
  });

  testWidgets('home light', (tester) async {
    await _configureView(tester);
    await _pump(tester, themeMode: 'light', auth: _SignedInAuth.new);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/home-light.png'),
    );
  });

  testWidgets('home dark', (tester) async {
    await _configureView(tester);
    await _pump(tester, themeMode: 'dark', auth: _SignedInAuth.new);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/home-dark.png'),
    );
  });

  testWidgets('showcase light', (tester) async {
    await _configureView(tester);
    await _pump(tester, themeMode: 'light', auth: _SignedInAuth.new);
    await tester.tap(find.text(AuthStrings.layoutReference));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/showcase-light.png'),
    );
  });

  testWidgets('showcase dark', (tester) async {
    await _configureView(tester);
    await _pump(tester, themeMode: 'dark', auth: _SignedInAuth.new);
    await tester.tap(find.text(AuthStrings.layoutReference));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/showcase-dark.png'),
    );
  });
}

Future<void> _configureView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(
  WidgetTester tester, {
  required String themeMode,
  required AuthController Function() auth,
}) async {
  SharedPreferences.setMockInitialValues({'theme_mode': themeMode});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      appEnvProvider.overrideWithValue(
        const AppEnv(
          flavor: AppFlavor.dev,
          apiBaseUrl: '',
          appName: 'Flutter Clean Architecture Riverpod',
        ),
      ),
      authControllerProvider.overrideWith(auth),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    fail('FLUTTER_ROOT is required to load Roboto for screenshots.');
  }
  final materialFonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
  await _loadFamily('Roboto', [
    '$materialFonts/Roboto-Thin.ttf',
    '$materialFonts/Roboto-Light.ttf',
    '$materialFonts/Roboto-Regular.ttf',
    '$materialFonts/Roboto-Medium.ttf',
    '$materialFonts/Roboto-Bold.ttf',
    '$materialFonts/Roboto-Black.ttf',
  ]);
  await _loadFamily('MaterialIcons', [
    '$materialFonts/MaterialIcons-Regular.otf',
  ]);
  final remix = File(
    'build/unit_test_assets/packages/remixicon/fonts/remix.ttf',
  );
  if (remix.existsSync()) {
    await _loadFamily('packages/remixicon/remix', [remix.path]);
  }
}

Future<void> _loadFamily(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final path in files) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

class _SignedOutAuth extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _SignedInAuth extends AuthController {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      session: AuthSession(token: 'token', email: 'dev@example.com'),
    );
  }
}

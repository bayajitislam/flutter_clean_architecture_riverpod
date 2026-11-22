import 'package:flutter_clean_architecture_riverpod/app.dart';
import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/routing/app_router.dart';
import 'package:flutter_clean_architecture_riverpod/core/routing/route_paths.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/theme_mode_controller.dart';
import 'package:flutter_clean_architecture_riverpod/core/widgets/app_loading.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/auth_strings.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required AuthController Function() auth,
    bool settle = true,
  }) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appEnvProvider.overrideWithValue(
          const AppEnv(flavor: AppFlavor.dev, apiBaseUrl: '', appName: 'Test'),
        ),
        authControllerProvider.overrideWith(auth),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Splash keeps a progress indicator animating.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
    return container;
  }

  testWidgets('unknown session stays on splash', (tester) async {
    await pumpApp(tester, auth: _UnknownAuth.new, settle: false);

    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text(AuthStrings.signIn), findsNothing);
    expect(find.text(AuthStrings.signedIn), findsNothing);
  });

  testWidgets('signed-out users are sent to login', (tester) async {
    final container = await pumpApp(tester, auth: _SignedOutAuth.new);
    final location = container.read(routerProvider).state.matchedLocation;

    expect(location, RoutePaths.login);
    expect(find.text(AuthStrings.signIn), findsOneWidget);
    expect(find.text(AuthStrings.signedIn), findsNothing);
  });

  testWidgets('signed-in users are sent to home', (tester) async {
    final container = await pumpApp(tester, auth: _SignedInAuth.new);
    final location = container.read(routerProvider).state.matchedLocation;

    expect(location, RoutePaths.home);
    expect(find.text(AuthStrings.signedIn), findsOneWidget);
    expect(find.text('dev@example.com'), findsOneWidget);
    expect(find.text(AuthStrings.signIn), findsNothing);
  });
}

class _UnknownAuth extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unknown);
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

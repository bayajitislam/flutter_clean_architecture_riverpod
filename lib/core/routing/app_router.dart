import 'package:flutter_clean_architecture_riverpod/core/routing/route_paths.dart';
import 'package:flutter_clean_architecture_riverpod/core/routing/splash_screen.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_clean_architecture_riverpod/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/layout/showcase_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (previous, next) {
    refresh.value++;
  });

  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      if (auth.status == AuthStatus.unknown) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return location == RoutePaths.login ? null : RoutePaths.login;
      }
      if (location == RoutePaths.login || location == RoutePaths.splash) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.showcase,
        builder: (context, state) => const ShowcaseScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

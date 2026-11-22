import 'package:flutter_clean_architecture_riverpod/core/constants/theme_strings.dart';
import 'package:flutter_clean_architecture_riverpod/core/extensions/context_extensions.dart';
import 'package:flutter_clean_architecture_riverpod/core/icons/app_icons.dart';
import 'package:flutter_clean_architecture_riverpod/core/routing/route_paths.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/theme_mode_controller.dart';
import 'package:flutter_clean_architecture_riverpod/core/widgets/app_dialog.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/auth_strings.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/responsive_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final email = auth.session?.email ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AuthStrings.homeTitle),
        actions: [
          IconButton(
            tooltip: _nextTheme(themeMode).tooltip,
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).toggle(),
            icon: Icon(_nextTheme(themeMode).icon),
          ),
        ],
      ),
      body: ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AuthStrings.signedIn,
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(email, style: context.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.large),
              Semantics(
                button: true,
                label: AuthStrings.layoutReference,
                child: OutlinedButton(
                  onPressed: () => context.go(RoutePaths.showcase),
                  child: const Text(AuthStrings.layoutReference),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Semantics(
                button: true,
                label: AuthStrings.signOut,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showAppConfirmDialog(
                      context,
                      title: AuthStrings.signOutTitle,
                      message: AuthStrings.signOutMessage,
                      confirmLabel: AuthStrings.signOut,
                    );
                    if (!confirmed || !context.mounted) {
                      return;
                    }
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
                  child: const Text(AuthStrings.signOut),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({IconData icon, String tooltip}) _nextTheme(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => (icon: AppIcons.darkMode, tooltip: ThemeStrings.useDark),
    ThemeMode.dark => (
      icon: AppIcons.systemMode,
      tooltip: ThemeStrings.useSystem,
    ),
    ThemeMode.system => (
      icon: AppIcons.lightMode,
      tooltip: ThemeStrings.useLight,
    ),
  };
}

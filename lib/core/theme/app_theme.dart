import 'package:flutter_clean_architecture_riverpod/core/theme/app_colors.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_radius.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_theme_extensions.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Material 3 light and dark themes built from the shared tokens.
abstract final class AppTheme {
  static ThemeData get light => _theme(Brightness.light);

  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );
    final text = AppTypography.textTheme(scheme);
    final status = brightness == Brightness.dark
        ? AppStatusColors.dark(scheme)
        : AppStatusColors.light(scheme);
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.mediumBorder);
    final buttonText = text.labelLarge;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      disabledColor: status.disabled,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeBorder,
          side: BorderSide(color: status.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.largeBorder,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        border: const OutlineInputBorder(borderRadius: AppRadius.mediumBorder),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBorder,
          borderSide: BorderSide(color: status.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBorder,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBorder,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBorder,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: buttonText,
          shape: shape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(textStyle: buttonText, shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: buttonText, shape: shape),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.largeBorder,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: shape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: shape),
      ),
    );
  }
}

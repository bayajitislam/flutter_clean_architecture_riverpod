import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_colors.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_radius.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_theme.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_theme_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses the brand seed and shared component styles', () {
    final theme = AppTheme.light;
    final status = theme.extension<AppStatusColors>();

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    expect(theme.colorScheme.primary, isNot(theme.colorScheme.onPrimary));
    expect(theme.colorScheme.surface, isNot(theme.colorScheme.onSurface));
    expect(theme.colorScheme.error, isNot(theme.colorScheme.onError));
    expect(status?.success, AppColors.success);
    expect(status?.warning, AppColors.warning);
    expect(status?.border, theme.colorScheme.outline);
    expect(theme.textTheme.displaySmall, isNotNull);
    expect(theme.textTheme.headlineMedium, isNotNull);
    expect(theme.textTheme.titleLarge, isNotNull);
    expect(theme.textTheme.bodyLarge?.color, theme.colorScheme.onSurface);
    expect(theme.textTheme.labelLarge, isNotNull);
    expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
    expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(
      theme.floatingActionButtonTheme.backgroundColor,
      theme.colorScheme.primaryContainer,
    );
    expect(theme.navigationBarTheme.backgroundColor, theme.colorScheme.surface);
    expect(
      theme.navigationRailTheme.backgroundColor,
      theme.colorScheme.surface,
    );
    final buttonShape = theme.filledButtonTheme.style?.shape?.resolve(
      const <WidgetState>{},
    );
    expect(
      buttonShape,
      const RoundedRectangleBorder(borderRadius: AppRadius.mediumBorder),
    );
  });

  test('dark theme keeps contrast and dark status colors', () {
    final theme = AppTheme.dark;
    final status = theme.extension<AppStatusColors>();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    expect(theme.colorScheme.onSurface, isNot(theme.colorScheme.surface));
    expect(status?.success, AppColors.successDark);
    expect(status?.onSuccess, AppColors.onSuccessDark);
    expect(status?.warning, AppColors.warningDark);
    expect(theme.textTheme.bodyMedium?.color, theme.colorScheme.onSurface);
    expect(theme.disabledColor, status?.disabled);
  });

  test('spacing and radius tokens stay on one scale', () {
    expect(AppSpacing.small, 8);
    expect(AppSpacing.medium, 16);
    expect(AppSpacing.large, 24);
    expect(AppSpacing.extraLarge, 32);
    expect(AppRadius.small, 4);
    expect(AppRadius.medium, 8);
    expect(AppRadius.large, 12);
    expect(AppRadius.extraLarge, 16);
    expect(AppRadius.circular, greaterThan(AppRadius.extraLarge));
  });
}

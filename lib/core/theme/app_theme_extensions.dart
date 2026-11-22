import 'package:flutter_clean_architecture_riverpod/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Semantic colors that [ColorScheme] does not define.
///
/// Read them with `context.statusColors`. Borders and disabled colors are
/// derived from the scheme when the theme is built.
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.border,
    required this.disabled,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color border;
  final Color disabled;

  static AppStatusColors light(ColorScheme scheme) {
    return AppStatusColors(
      success: AppColors.success,
      onSuccess: AppColors.onSuccess,
      warning: AppColors.warning,
      onWarning: AppColors.onWarning,
      border: scheme.outline,
      disabled: scheme.onSurface.withValues(alpha: 0.38),
    );
  }

  static AppStatusColors dark(ColorScheme scheme) {
    return AppStatusColors(
      success: AppColors.successDark,
      onSuccess: AppColors.onSuccessDark,
      warning: AppColors.warningDark,
      onWarning: AppColors.onWarningDark,
      border: scheme.outline,
      disabled: scheme.onSurface.withValues(alpha: 0.38),
    );
  }

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? border,
    Color? disabled,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      border: border ?? this.border,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppStatusColors lerp(
    covariant ThemeExtension<AppStatusColors>? other,
    double t,
  ) {
    if (other is! AppStatusColors) {
      return this;
    }
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      border: Color.lerp(border, other.border, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}

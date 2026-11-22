import 'package:material_ui/material_ui.dart';

/// Brand and semantic colors.
///
/// [brand] is the only seed for light and dark [ColorScheme]s. Change it
/// here to recolor the application. Success and warning stay explicit because
/// Material has no roles for them.
abstract final class AppColors {
  static const brand = Color(0xFF1565C0);

  static const success = Color(0xFF1B7F4E);
  static const onSuccess = Color(0xFFFFFFFF);
  static const successDark = Color(0xFF8FD9B0);
  static const onSuccessDark = Color(0xFF00331A);

  static const warning = Color(0xFFB26A00);
  static const onWarning = Color(0xFFFFFFFF);
  static const warningDark = Color(0xFFFFCC80);
  static const onWarningDark = Color(0xFF3E2723);
}

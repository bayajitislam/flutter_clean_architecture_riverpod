import 'package:material_ui/material_ui.dart';

/// Text styles for both brightness values.
///
/// Material 3 roles are the tokens: display, headline, title, body, and
/// label. Buttons use `labelLarge`. Set [fontFamily] to apply one family
/// everywhere.
abstract final class AppTypography {
  static const String? fontFamily = null;

  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
    ).textTheme;
    return base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: fontFamily,
    );
  }
}

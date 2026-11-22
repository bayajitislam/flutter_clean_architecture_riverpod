import 'package:flutter_clean_architecture_riverpod/core/theme/app_theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

extension ContextX on BuildContext {
  ThemeData get appTheme => Theme.of(this);

  ColorScheme get colors => appTheme.colorScheme;

  TextTheme get textTheme => appTheme.textTheme;

  AppStatusColors get statusColors => appTheme.extension<AppStatusColors>()!;
}

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_theme_extensions.dart';

extension ContextX on BuildContext {
  ThemeData get appTheme => Theme.of(this);

  ColorScheme get colors => appTheme.colorScheme;

  TextTheme get textTheme => appTheme.textTheme;

  AppStatusColors get statusColors => appTheme.extension<AppStatusColors>()!;
}

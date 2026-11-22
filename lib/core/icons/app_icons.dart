import 'package:material_ui/material_ui.dart';
import 'package:remixicon/remixicon.dart';

/// Icons for screens and shared widgets.
///
/// Remix glyphs are the default. The Material fields are Flutter's built-in
/// [Icons]. Add a new icon here instead of importing either set in a feature.
abstract final class AppIcons {
  static const dashboard = RemixIcons.dashboard_line;
  static const layout = RemixIcons.layout_line;
  static const menu = RemixIcons.menu_line;
  static const layers = RemixIcons.stack_line;
  static const darkMode = RemixIcons.moon_line;
  static const lightMode = RemixIcons.sun_line;
  static const systemMode = RemixIcons.contrast_2_line;

  static const add = Icons.add;
  static const arrowBack = Icons.arrow_back;
  static const check = Icons.check;
  static const close = Icons.close;
  static const search = Icons.search;
}

import 'package:flutter_clean_architecture_riverpod/shared/enums/screen_size.dart';
import 'package:material_ui/material_ui.dart';

/// Picks a layout from the width [LayoutBuilder] receives.
///
/// A missing tablet layout uses [mobile]. A missing desktop layout uses
/// [tablet], then [mobile]. Window resizing is picked up on the next layout.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.breakpoints = defaultBreakpoints,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final AppBreakpoints breakpoints;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = breakpoints.sizeFor(constraints.maxWidth);
        return switch (size) {
          ScreenSize.desktop => desktop ?? tablet ?? mobile,
          ScreenSize.tablet => tablet ?? mobile,
          ScreenSize.mobile => mobile,
        };
      },
    );
  }
}

/// Width class chosen from available layout constraints.
enum ScreenSize { mobile, tablet, desktop }

/// Widths that choose [ScreenSize].
///
/// Defaults are 600 for tablet and 1024 for desktop. [tabletExpanded] is still
/// a tablet width; it only lets a navigation rail show labels in landscape.
class AppBreakpoints {
  const AppBreakpoints({
    this.tablet = 600,
    this.desktop = 1024,
    this.tabletExpanded = 840,
  });

  final double tablet;
  final double desktop;
  final double tabletExpanded;

  ScreenSize sizeFor(double width) {
    if (width >= desktop) {
      return ScreenSize.desktop;
    }
    if (width >= tablet) {
      return ScreenSize.tablet;
    }
    return ScreenSize.mobile;
  }
}

const defaultBreakpoints = AppBreakpoints();

/// Maps a width in logical pixels to a [ScreenSize].
ScreenSize screenSizeOf(
  double width, {
  AppBreakpoints breakpoints = defaultBreakpoints,
}) {
  return breakpoints.sizeFor(width);
}

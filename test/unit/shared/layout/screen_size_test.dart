import 'package:flutter_clean_architecture_riverpod/shared/enums/screen_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default breakpoints split mobile, tablet, and desktop', () {
    expect(screenSizeOf(599), ScreenSize.mobile);
    expect(screenSizeOf(600), ScreenSize.tablet);
    expect(screenSizeOf(1023), ScreenSize.tablet);
    expect(screenSizeOf(1024), ScreenSize.desktop);
  });

  test('breakpoints can be replaced', () {
    const breakpoints = AppBreakpoints(tablet: 720, desktop: 1280);

    expect(screenSizeOf(700, breakpoints: breakpoints), ScreenSize.mobile);
    expect(screenSizeOf(720, breakpoints: breakpoints), ScreenSize.tablet);
    expect(screenSizeOf(1280, breakpoints: breakpoints), ScreenSize.desktop);
  });
}

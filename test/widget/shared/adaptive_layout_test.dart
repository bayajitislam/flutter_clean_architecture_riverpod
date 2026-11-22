import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/adaptive_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches layout when the available width changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> pump(double width) {
      return tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              height: 700,
              child: const AdaptiveLayout(
                mobile: Text('mobile-layout'),
                tablet: Text('tablet-layout'),
                desktop: Text('desktop-layout'),
              ),
            ),
          ),
        ),
      );
    }

    await pump(599);
    expect(find.text('mobile-layout'), findsOneWidget);

    await pump(600);
    expect(find.text('tablet-layout'), findsOneWidget);

    await pump(1024);
    expect(find.text('desktop-layout'), findsOneWidget);
  });

  testWidgets('missing tablet and desktop layouts fall back to mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 1200,
            height: 700,
            child: AdaptiveLayout(mobile: Text('mobile-only')),
          ),
        ),
      ),
    );

    expect(find.text('mobile-only'), findsOneWidget);
  });

  testWidgets('a missing desktop layout falls back to tablet', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 1200,
            height: 700,
            child: AdaptiveLayout(
              mobile: Text('mobile-layout'),
              tablet: Text('tablet-layout'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('tablet-layout'), findsOneWidget);
  });
}

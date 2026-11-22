import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/layout/showcase_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWidth(WidgetTester tester, double width) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              height: 700,
              child: const ShowcaseScreen(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('mobile uses bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpWidth(tester, 400);

    expect(find.byKey(const Key('showcase-mobile')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablet uses a rail and expands it in landscape', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpWidth(tester, 700);
    expect(find.byKey(const Key('showcase-tablet')), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );

    await pumpWidth(tester, 900);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('desktop uses the sidebar and the same selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpWidth(tester, 1100);

    expect(find.byKey(const Key('showcase-desktop')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('One controller feeds every layout.'), findsOneWidget);

    await tester.tap(find.text('State'));
    await tester.pump();

    expect(
      find.text('Tablet and desktop read the same ShowcaseState.'),
      findsOneWidget,
    );
  });
}

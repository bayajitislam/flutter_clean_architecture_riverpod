import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/widgets/shared/showcase_chrome.dart';
import 'package:flutter_clean_architecture_riverpod/shared/enums/screen_size.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/adaptive_navigation.dart';
import 'package:material_ui/material_ui.dart';

class ShowcaseTabletScreen extends StatelessWidget {
  const ShowcaseTabletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded =
            constraints.maxWidth >= defaultBreakpoints.tabletExpanded;
        return ShowcaseChrome(
          key: const Key('showcase-tablet'),
          style: AdaptiveNavigationStyle.rail,
          extended: expanded,
        );
      },
    );
  }
}

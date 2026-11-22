import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/widgets/shared/showcase_chrome.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/adaptive_navigation.dart';
import 'package:material_ui/material_ui.dart';

class ShowcaseMobileScreen extends StatelessWidget {
  const ShowcaseMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShowcaseChrome(
      key: Key('showcase-mobile'),
      style: AdaptiveNavigationStyle.bottom,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/widgets/shared/showcase_chrome.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/adaptive_navigation.dart';

class ShowcaseDesktopScreen extends StatelessWidget {
  const ShowcaseDesktopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShowcaseChrome(
      key: Key('showcase-desktop'),
      style: AdaptiveNavigationStyle.sidebar,
    );
  }
}

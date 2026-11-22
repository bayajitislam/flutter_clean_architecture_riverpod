import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/providers/showcase_controller.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/widgets/shared/showcase_detail.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/adaptive_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared chrome. Each screen chooses the navigation style.
class ShowcaseChrome extends ConsumerWidget {
  const ShowcaseChrome({required this.style, this.extended = false, super.key});

  final AdaptiveNavigationStyle style;
  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(showcaseControllerProvider).selectedIndex;
    final section = ShowcaseController.sections[selected];
    return AdaptiveNavigation(
      style: style,
      extended: extended,
      selectedIndex: selected,
      destinations: [
        for (final item in ShowcaseController.sections)
          AppDestination(label: item.label, icon: item.icon),
      ],
      onSelected: (index) {
        ref.read(showcaseControllerProvider.notifier).select(index);
      },
      body: ShowcaseDetail(section: section),
    );
  }
}

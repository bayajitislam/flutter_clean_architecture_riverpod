import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A section of the layout reference. The three screens share this list.
class ShowcaseSection {
  const ShowcaseSection({
    required this.label,
    required this.icon,
    required this.detail,
  });

  final String label;
  final IconData icon;
  final String detail;
}

class ShowcaseState {
  const ShowcaseState({this.selectedIndex = 0});

  final int selectedIndex;
}

/// Selection shared by the mobile, tablet, and desktop layouts.
class ShowcaseController extends Notifier<ShowcaseState> {
  static const sections = <ShowcaseSection>[
    ShowcaseSection(
      label: 'Layout',
      icon: AppIcons.layout,
      detail: 'One controller feeds every layout.',
    ),
    ShowcaseSection(
      label: 'Navigation',
      icon: AppIcons.menu,
      detail: 'Navigation changes with width. The selection does not.',
    ),
    ShowcaseSection(
      label: 'State',
      icon: AppIcons.layers,
      detail: 'Tablet and desktop read the same ShowcaseState.',
    ),
  ];

  @override
  ShowcaseState build() => const ShowcaseState();

  void select(int index) {
    if (index < 0 || index >= sections.length) {
      return;
    }
    state = ShowcaseState(selectedIndex: index);
  }
}

final showcaseControllerProvider =
    NotifierProvider<ShowcaseController, ShowcaseState>(ShowcaseController.new);

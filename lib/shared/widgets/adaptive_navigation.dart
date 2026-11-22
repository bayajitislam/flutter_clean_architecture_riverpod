import 'package:material_ui/material_ui.dart';

/// One destination in [AdaptiveNavigation].
class AppDestination {
  const AppDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Where the destinations are drawn. Screens choose this; width does not.
enum AdaptiveNavigationStyle { bottom, rail, sidebar }

/// Navigation chrome that does not own the selected index.
///
/// The caller keeps that index in a shared provider so mobile, tablet, and
/// desktop stay on the same item.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    required this.style,
    this.extended = false,
    super.key,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final AdaptiveNavigationStyle style;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      AdaptiveNavigationStyle.bottom => _bottom(),
      AdaptiveNavigationStyle.rail => _rail(extended: extended),
      AdaptiveNavigationStyle.sidebar => _rail(extended: true, width: 240),
    };
  }

  Widget _bottom() {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  Widget _rail({required bool extended, double? width}) {
    final rail = NavigationRail(
      extended: extended,
      minExtendedWidth: width ?? 256,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
    return Scaffold(
      body: Row(
        children: [
          if (width == null) rail else SizedBox(width: width, child: rail),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

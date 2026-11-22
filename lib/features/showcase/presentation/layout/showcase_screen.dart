import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/screens/desktop/showcase_desktop_screen.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/screens/mobile/showcase_mobile_screen.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/screens/tablet/showcase_tablet_screen.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/adaptive_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Reference screen for separate mobile, tablet, and desktop layouts.
///
/// The three children read the same showcase controller. They do not keep
/// their own selection.
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveLayout(
      mobile: ShowcaseMobileScreen(),
      tablet: ShowcaseTabletScreen(),
      desktop: ShowcaseDesktopScreen(),
    );
  }
}

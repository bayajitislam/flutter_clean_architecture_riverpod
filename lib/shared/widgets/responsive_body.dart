import 'package:flutter_clean_architecture_riverpod/shared/enums/screen_size.dart';
import 'package:material_ui/material_ui.dart';

/// Centers page content and caps its width on larger screens.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = screenSizeOf(constraints.maxWidth);
        final maxWidth = switch (size) {
          ScreenSize.mobile => 480.0,
          ScreenSize.tablet => 720.0,
          ScreenSize.desktop => 960.0,
        };
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

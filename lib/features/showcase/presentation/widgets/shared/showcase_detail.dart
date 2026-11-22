import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/features/showcase/presentation/providers/showcase_controller.dart';
import 'package:material_ui/material_ui.dart';

/// Detail pane used by every showcase layout.
class ShowcaseDetail extends StatelessWidget {
  const ShowcaseDetail({required this.section, super.key});

  final ShowcaseSection section;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Row(
          children: [
            Icon(section.icon),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                section.label,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(section.detail),
      ],
    );
  }
}

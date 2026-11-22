import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/core/widgets/app_button.dart';

/// Full-width message for a failed screen.
class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.medium),
          AppButton(label: 'Try again', onPressed: onRetry),
        ],
      ],
    );
  }
}

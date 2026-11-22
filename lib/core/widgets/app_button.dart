import 'package:material_ui/material_ui.dart';

/// Primary action button used by feature screens.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.tooltip,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? Semantics(
                label: '$label, loading',
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(label),
      ),
    );
    if (tooltip == null) {
      return Semantics(button: true, label: label, child: button);
    }
    return Tooltip(
      message: tooltip!,
      child: Semantics(button: true, label: label, child: button),
    );
  }
}

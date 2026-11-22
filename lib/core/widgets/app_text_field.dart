import 'package:material_ui/material_ui.dart';

/// Labeled text field with a single error message.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    );
  }
}

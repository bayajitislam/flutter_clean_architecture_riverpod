import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/core/widgets/app_button.dart';
import 'package:flutter_clean_architecture_riverpod/core/widgets/app_text_field.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/auth_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Email and password fields for [LoginScreen].
class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.emailError,
    required this.passwordError,
    required this.isSubmitting,
    required this.onSubmit,
    this.failureMessage,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? passwordError;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? failureMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: emailController,
          label: AuthStrings.emailLabel,
          errorText: emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.medium),
        AppTextField(
          controller: passwordController,
          label: AuthStrings.passwordLabel,
          errorText: passwordError,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (failureMessage != null) ...[
          const SizedBox(height: AppSpacing.medium),
          Semantics(
            liveRegion: true,
            child: Text(failureMessage!, textAlign: TextAlign.center),
          ),
        ],
        const SizedBox(height: AppSpacing.large),
        AppButton(
          label: AuthStrings.signIn,
          isLoading: isSubmitting,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

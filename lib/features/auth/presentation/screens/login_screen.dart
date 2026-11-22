import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/config/app_env.dart';
import 'package:flutter_clean_architecture_riverpod/core/extensions/context_extensions.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/app_spacing.dart';
import 'package:flutter_clean_architecture_riverpod/core/utils/validators.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/domain/entities/credentials.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_clean_architecture_riverpod/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter_clean_architecture_riverpod/shared/widgets/responsive_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = Validators.email(_emailController.text);
    final passwordError = Validators.password(_passwordController.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          Credentials(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final appName = ref.watch(appEnvProvider).appName;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              const SizedBox(height: 48),
              Text(appName, style: context.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Sign in to continue',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                emailError: _emailError,
                passwordError: _passwordError,
                isSubmitting: auth.isSubmitting,
                failureMessage: auth.failure?.message,
                onSubmit: () => unawaited(_submit()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

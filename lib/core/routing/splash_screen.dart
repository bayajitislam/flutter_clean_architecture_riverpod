import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/widgets/app_loading.dart';

/// Shown while the session is restored at startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoading(message: 'Loading'));
  }
}

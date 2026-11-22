import 'package:flutter_clean_architecture_riverpod/core/widgets/app_loading.dart';
import 'package:material_ui/material_ui.dart';

/// Shown while the session is restored at startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoading(message: 'Loading'));
  }
}

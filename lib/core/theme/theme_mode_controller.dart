import 'package:flutter_clean_architecture_riverpod/core/storage/preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded in `main` before [runApp]. Tests that read theme must override this.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden at startup.');
});

/// Preference store for non-sensitive values.
final preferencesStorageProvider = Provider<PreferencesStorage>((ref) {
  return PreferencesStorage(ref.watch(sharedPreferencesProvider));
});

/// Light, dark, and system appearance, persisted in [PreferencesStorage].
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.read(preferencesStorageProvider).readThemeMode();
  }

  /// Applies [mode] immediately and stores it when it changed.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    await ref.read(preferencesStorageProvider).writeThemeMode(mode);
  }

  /// Cycles light, then dark, then system.
  Future<void> toggle() {
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    return setThemeMode(next);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

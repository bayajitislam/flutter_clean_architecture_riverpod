import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_riverpod/core/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple preferences that are safe to keep outside secure storage.
class PreferencesStorage {
  const PreferencesStorage(this._preferences);

  final SharedPreferences _preferences;

  ThemeMode readThemeMode() {
    return switch (_preferences.getString(StorageKeys.themeMode)) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    return _preferences.setString(StorageKeys.themeMode, value);
  }
}

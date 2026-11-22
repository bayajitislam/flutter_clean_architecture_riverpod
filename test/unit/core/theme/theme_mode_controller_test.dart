import 'package:flutter_clean_architecture_riverpod/core/storage/preferences_storage.dart';
import 'package:flutter_clean_architecture_riverpod/core/theme/theme_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    ({
      ProviderContainer container,
      _RecordingPreferences storage,
      SharedPreferences preferences,
    })
  >
  open(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final preferences = await SharedPreferences.getInstance();
    final storage = _RecordingPreferences(preferences);
    final container = ProviderContainer(
      overrides: [preferencesStorageProvider.overrideWithValue(storage)],
    );
    return (container: container, storage: storage, preferences: preferences);
  }

  test('restores light, dark, and system', () async {
    final light = await open({'theme_mode': 'light'});
    final dark = await open({'theme_mode': 'dark'});
    final system = await open({'theme_mode': 'system'});
    final missing = await open({});
    addTearDown(light.container.dispose);
    addTearDown(dark.container.dispose);
    addTearDown(system.container.dispose);
    addTearDown(missing.container.dispose);

    expect(light.container.read(themeModeControllerProvider), ThemeMode.light);
    expect(dark.container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(
      system.container.read(themeModeControllerProvider),
      ThemeMode.system,
    );
    expect(
      missing.container.read(themeModeControllerProvider),
      ThemeMode.system,
    );
    expect(light.storage.writes, 0);
  });

  test('switches modes and skips a write when the mode is unchanged', () async {
    final opened = await open({'theme_mode': 'light'});
    addTearDown(opened.container.dispose);
    final notifier = opened.container.read(
      themeModeControllerProvider.notifier,
    );

    await notifier.setThemeMode(ThemeMode.light);
    expect(opened.storage.writes, 0);

    await notifier.setThemeMode(ThemeMode.dark);
    expect(opened.container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(opened.preferences.getString('theme_mode'), 'dark');

    await notifier.setThemeMode(ThemeMode.system);
    expect(
      opened.container.read(themeModeControllerProvider),
      ThemeMode.system,
    );
    expect(opened.preferences.getString('theme_mode'), 'system');

    await notifier.toggle();
    expect(opened.container.read(themeModeControllerProvider), ThemeMode.light);
    expect(opened.storage.writes, 3);
  });
}

class _RecordingPreferences extends PreferencesStorage {
  _RecordingPreferences(super.preferences);

  var writes = 0;

  @override
  Future<void> writeThemeMode(ThemeMode mode) {
    writes += 1;
    return super.writeThemeMode(mode);
  }
}

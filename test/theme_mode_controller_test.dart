import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:formapi/core/storage/shared_preferences_provider.dart';
import 'package:formapi/core/theme/theme_mode_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> createContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('default eh ThemeMode.system', () async {
    final container = await createContainer();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('toggleLightDark alterna e persiste', () async {
    final container = await createContainer();
    final prefs = container.read(sharedPreferencesProvider);
    final notifier = container.read(themeModeProvider.notifier);

    notifier.toggleLightDark();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');

    notifier.toggleLightDark();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('setMode persiste light dark e system', () async {
    final container = await createContainer();
    final prefs = container.read(sharedPreferencesProvider);
    final notifier = container.read(themeModeProvider.notifier);

    notifier.setMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');

    notifier.setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');

    notifier.setMode(ThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(prefs.getString('theme_mode'), 'system');
  });
}

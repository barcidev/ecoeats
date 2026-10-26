import 'package:ecoeats/features/profile/application/theme_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ThemeMode> load() =>
      ProviderContainer.test().read(themeModeControllerProvider.future);

  test('starts on the system appearance', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await load(), ThemeMode.system);
  });

  test('reads the stored choice', () async {
    SharedPreferences.setMockInitialValues({'profile.appearance': 'dark'});
    expect(await load(), ThemeMode.dark);
  });

  test('an unknown stored value falls back to the system', () async {
    SharedPreferences.setMockInitialValues({'profile.appearance': 'purple'});
    expect(await load(), ThemeMode.system);
  });

  test('a choice applies at once and survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer.test();
    await container.read(themeModeControllerProvider.future);

    final saving = container
        .read(themeModeControllerProvider.notifier)
        .choose(ThemeMode.light);
    expect(container.read(themeModeControllerProvider).value, ThemeMode.light);
    await saving;

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('profile.appearance'), 'light');
    expect(await load(), ThemeMode.light);
  });
}

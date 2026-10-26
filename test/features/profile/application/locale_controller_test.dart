import 'package:ecoeats/features/profile/application/locale_controller.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  Future<LocaleChoice> load() =>
      ProviderContainer.test().read(localeControllerProvider.future);

  test('starts on the system language, which follows the device', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await load(), LocaleChoice.system);
    expect(LocaleSettings.currentLocale, AppLocaleUtils.findDeviceLocale());
  });

  test('applies the stored choice when it loads', () async {
    SharedPreferences.setMockInitialValues({'profile.language': 'english'});

    expect(await load(), LocaleChoice.english);
    expect(LocaleSettings.currentLocale, AppLocale.en);
  });

  test(
    'a choice changes the language at once and survives a restart',
    () async {
      SharedPreferences.setMockInitialValues({'profile.language': 'english'});
      final container = ProviderContainer.test();
      await container.read(localeControllerProvider.future);

      await container
          .read(localeControllerProvider.notifier)
          .choose(LocaleChoice.spanish);

      expect(
        container.read(localeControllerProvider).value,
        LocaleChoice.spanish,
      );
      expect(LocaleSettings.currentLocale, AppLocale.es);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('profile.language'), 'spanish');
      expect(await load(), LocaleChoice.spanish);
    },
  );

  test('an unknown stored value falls back to the system', () async {
    SharedPreferences.setMockInitialValues({'profile.language': 'klingon'});
    expect(await load(), LocaleChoice.system);
  });
}

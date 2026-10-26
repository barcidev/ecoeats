import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_controller.g.dart';

enum LocaleChoice { system, spanish, english }

/// The language the customer chose in the profile, kept on the device and
/// applied through slang, which the translations and the per-language
/// formats already follow. `main` loads it before the first frame.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  static const _key = 'profile.language';

  @override
  Future<LocaleChoice> build() async {
    final preferences = await SharedPreferences.getInstance();
    final choice =
        LocaleChoice.values.asNameMap()[preferences.getString(_key)] ?? .system;
    await _apply(choice);
    return choice;
  }

  /// Changes the language and then stores the choice.
  Future<void> choose(LocaleChoice choice) async {
    await _apply(choice);
    state = AsyncData(choice);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, choice.name);
  }

  // The device's language falls back to Spanish when it is neither one.
  Future<void> _apply(LocaleChoice choice) => switch (choice) {
    .system => LocaleSettings.useDeviceLocale(),
    .spanish => LocaleSettings.setLocale(AppLocale.es),
    .english => LocaleSettings.setLocale(AppLocale.en),
  };
}

import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_controller.g.dart';

/// The appearance the customer chose in the profile, kept on the device.
/// `main` loads it before the first frame, so the app never flashes the
/// other theme.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const _key = 'profile.appearance';

  @override
  Future<ThemeMode> build() async {
    final preferences = await SharedPreferences.getInstance();
    return ThemeMode.values.asNameMap()[preferences.getString(_key)] ?? .system;
  }

  /// Applies [mode] at once and stores it.
  Future<void> choose(ThemeMode mode) async {
    state = AsyncData(mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, mode.name);
  }
}

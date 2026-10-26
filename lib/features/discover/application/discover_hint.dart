import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'discover_hint.g.dart';

/// Whether Discover still owes its first-time hint: shown until the customer
/// changes page or taps it once, then never again on this device.
@riverpod
class DiscoverHint extends _$DiscoverHint {
  static const _key = 'discover.hintSeen';

  @override
  Future<bool> build() async {
    final preferences = await SharedPreferences.getInstance();
    return !(preferences.getBool(_key) ?? false);
  }

  /// Hides the hint at once and remembers it.
  Future<void> dismiss() async {
    if (state.value == false) return;
    state = const AsyncData(false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }
}

import 'package:ecoeats/features/discover/application/discover_hint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the hint shows the first time', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer.test();
    expect(await container.read(discoverHintProvider.future), isTrue);
  });

  test('once dismissed it hides, also after reopening', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer.test();
    await first.read(discoverHintProvider.future);
    await first.read(discoverHintProvider.notifier).dismiss();
    expect(first.read(discoverHintProvider).value, isFalse);

    final reopened = ProviderContainer.test();
    expect(await reopened.read(discoverHintProvider.future), isFalse);
  });

  test('a device that already saw it never shows it', () async {
    SharedPreferences.setMockInitialValues({'discover.hintSeen': true});
    final container = ProviderContainer.test();
    expect(await container.read(discoverHintProvider.future), isFalse);
  });
}

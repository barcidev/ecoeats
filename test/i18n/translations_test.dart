import 'dart:io';

import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

Set<String> _keys(Object? node, [String prefix = '']) {
  if (node is! YamlMap) return {prefix};
  return {
    for (final MapEntry(:key, :value) in node.entries)
      ..._keys(value, prefix.isEmpty ? '$key' : '$prefix.$key'),
  };
}

Map<String, Set<String>> _namespaces(String locale) => {
  for (final file in Directory('lib/i18n/$locale').listSync().whereType<File>())
    if (file.path.endsWith('.i18n.yaml'))
      file.uri.pathSegments.last: _keys(loadYaml(file.readAsStringSync())),
};

void main() {
  final es = AppLocale.es.buildSync();
  late final Translations en;

  // English is a deferred library; the app loads it through LocaleSettings.
  setUpAll(() async => en = await AppLocale.en.build());

  test('Spanish and English define the same keys', () {
    final spanish = _namespaces('es');
    final english = _namespaces('en');
    expect(english.keys.toSet(), spanish.keys.toSet());
    for (final MapEntry(key: file, value: keys) in spanish.entries) {
      expect(english[file], keys, reason: file);
    }
  });

  test('shared copy reads naturally in each language', () {
    expect(es.common.retryIn(time: '0:42'), 'Intenta en 0:42');
    expect(en.common.retryIn(time: '0:42'), 'Try again in 0:42');
    expect(en.common.actions.retry, 'Try again');
  });
}

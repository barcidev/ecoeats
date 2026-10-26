import 'dart:io';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/i18n/failure_text.dart';
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

  test('dishes are counted in the plural of each language', () {
    expect(es.dishes.home.count(n: 12), '12 platos');
    expect(en.dishes.home.count(n: 12), '12 dishes');
    expect(es.dishes.home.count(n: 1), '1 plato');
    expect(en.dishes.home.count(n: 1), '1 dish');
  });

  test('English has its own voice', () {
    expect(es.auth.welcome.headline, 'Comida colombiana, sin afán.');
    expect(en.auth.welcome.headline, 'Colombian food, unhurried.');
  });

  test('shared copy reads naturally in each language', () {
    expect(es.common.retryIn(time: '0:42'), 'Intenta en 0:42');
    expect(en.common.retryIn(time: '0:42'), 'Try again in 0:42');
    expect(en.common.actions.retry, 'Try again');
  });

  group('failure text', () {
    test('each failure has its own words in each language', () {
      const failures = <AppFailure>[
        AppFailure.offline(),
        AppFailure.timeout(),
        AppFailure.rateLimited(retryAfter: Duration(seconds: 42)),
        AppFailure.server(status: 500),
        AppFailure.notFound(),
        AppFailure.unauthorized(),
        AppFailure.validation(fieldErrors: {'correo': 'x'}),
        AppFailure.conflict(field: .email),
        AppFailure.conflict(field: .document),
        AppFailure.unknown(),
      ];
      for (final t in [es, en]) {
        final texts = failures.map((failure) => failureMessage(failure, t));
        expect(texts.toSet(), hasLength(failures.length));
        expect(texts, everyElement(isNotEmpty));
      }
      expect(
        failureMessage(const AppFailure.conflict(field: .email), en),
        "There's already an account with that email.",
      );
    });

    test('a server failure carries its reference', () {
      const failure = AppFailure.server(status: 500, requestId: 'ab12');
      final spanish = failureCopy(failure, es);
      expect(spanish.title, 'Algo se nos quemó en la cocina.');
      expect(spanish.reference, 'Ref. ab12');
      expect(failureCopy(failure, en).reference, 'Ref. ab12');
      expect(
        failureCopy(const AppFailure.server(status: 503), es).reference,
        isNull,
      );
    });

    test('the server message fills in only in Spanish', () {
      const conflict = AppFailure.conflict(message: 'Ese valor ya existe');
      expect(failureMessage(conflict, es), 'Ese valor ya existe');
      expect(failureMessage(conflict, en), en.errors.conflict.other);

      const expired = AppFailure.validation(
        fieldErrors: {},
        message: 'OTP inválido o expirado',
      );
      expect(failureMessage(expired, es), 'OTP inválido o expirado');
      expect(failureMessage(expired, en), en.errors.validation);
    });
  });
}

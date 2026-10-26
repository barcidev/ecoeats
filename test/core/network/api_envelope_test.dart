import 'package:dio/dio.dart';
import 'package:ecoeats/core/config/env.dart';
import 'package:ecoeats/core/network/api_envelope.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/network/dio_provider.dart';
import 'package:ecoeats/core/network/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  group('readEnvelope', () {
    test('returns the parsed data of a successful envelope', () {
      final value = readEnvelope({
        'success': true,
        'message': 'OK',
        'data': 3,
      }, (data) => (data! as int) * 2);
      expect(value, 6);
    });

    test('a body that is not an envelope is an unknown failure', () {
      expect(
        () => readEnvelope('<html>', (data) => data),
        throwsA(isA<UnknownFailure>()),
      );
    });

    test('a parser that throws is an unknown failure', () {
      expect(
        () => readEnvelope({
          'success': true,
          'message': 'OK',
          'data': 'x',
        }, (data) => (data! as Map)['id']),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('request', () {
    late FakeHttpAdapter adapter;
    late Dio dio;

    setUp(() {
      adapter = FakeHttpAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
    });

    test('parses the data of a 200', () async {
      adapter.ok('GET', '/api/dish', [1, 2]);
      final value = await request(
        () => dio.get<Object?>('/api/dish'),
        (data) => (data! as List).length,
      );
      expect(value, 2);
    });

    test('throws the mapped failure of an error status', () async {
      adapter.reply(
        'GET',
        '/api/dish/x',
        status: 404,
        body: {'success': false, 'message': 'Plato no encontrado'},
      );
      await expectLater(
        request(() => dio.get<Object?>('/api/dish/x'), (data) => data),
        throwsA(const AppFailure.notFound(message: 'Plato no encontrado')),
      );
    });

    test('throws offline when the connection fails', () async {
      adapter.fail('GET', '/api/dish', .connectionError);
      await expectLater(
        request(() => dio.get<Object?>('/api/dish'), (data) => data),
        throwsA(const AppFailure.offline()),
      );
    });
  });

  group('dioProvider', () {
    test('points at the configured API with the plan timeouts', () {
      final container = ProviderContainer.test();
      final options = container.read(dioProvider).options;
      expect(options.baseUrl, Env.apiBaseUrl);
      expect(
        Env.apiBaseUrl,
        'https://ecoeats-api-kotlin-production.up.railway.app',
      );
      expect(options.connectTimeout, const Duration(seconds: 10));
      expect(options.receiveTimeout, const Duration(seconds: 15));
    });
  });

  group('warmUp', () {
    test('ignores a 503 DOWN', () async {
      final adapter = FakeHttpAdapter()
        ..reply('GET', '/health', status: 503, body: {'status': 'DOWN'});
      final dio = Dio()..httpClientAdapter = adapter;
      await expectLater(warmUp(dio), completes);
      expect(adapter.requests.single.path, '/health');
    });

    test('ignores a lost connection', () async {
      final adapter = FakeHttpAdapter()
        ..fail('GET', '/health', .connectionError);
      final dio = Dio()..httpClientAdapter = adapter;
      await expectLater(warmUp(dio), completes);
    });
  });
}

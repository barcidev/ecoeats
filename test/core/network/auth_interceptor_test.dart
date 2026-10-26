import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/auth_interceptor.dart';
import 'package:ecoeats/core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;
  late int unauthorized;
  String? token;

  setUp(() {
    adapter = FakeHttpAdapter();
    unauthorized = 0;
    token = 'jwt';
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(
          readToken: () async => token,
          onUnauthorized: () => unauthorized++,
        ),
      );
  });

  test('authenticated routes carry the Bearer token', () async {
    adapter.ok('GET', '/api/dish', <Object?>[]);
    await dio.get<Object?>('/api/dish');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt');
  });

  test('security routes carry no token', () async {
    adapter.ok('POST', '/api/securities/login', null);
    await dio.post<Object?>('/api/securities/login');
    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('a 401 on an authenticated route ends the session', () async {
    adapter.reply('GET', '/api/dish', status: 401, body: {'success': false});
    await expectLater(
      dio.get<Object?>('/api/dish'),
      throwsA(isA<DioException>()),
    );
    expect(unauthorized, 1);
  });

  test('a 401 on login is just a wrong password', () async {
    adapter.reply(
      'POST',
      '/api/securities/login',
      status: 401,
      body: {'success': false},
    );
    await expectLater(
      dio.post<Object?>('/api/securities/login'),
      throwsA(isA<DioException>()),
    );
    expect(unauthorized, 0);
  });

  test('without a token there is no header and no session to end', () async {
    token = null;
    adapter.reply('GET', '/api/dish', status: 401, body: {'success': false});
    await expectLater(
      dio.get<Object?>('/api/dish'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    expect(unauthorized, 0);
  });

  test('the app Dio has the interceptor', () {
    final container = ProviderContainer.test();
    expect(
      container.read(dioProvider).interceptors.whereType<AuthInterceptor>(),
      hasLength(1),
    );
  });
}

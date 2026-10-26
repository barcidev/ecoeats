import 'dart:convert';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:ecoeats/features/auth/data/auth_dtos.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

class _MemoryTokenStore implements TokenStore {
  String? token;
  final names = <String, String>{};

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readFirstNames(String email) async => names[email];

  @override
  Future<void> writeFirstNames(String email, String firstNames) async =>
      names[email] = firstNames;
}

final _now = DateTime.utc(2026, 10, 25, 12);

String _jwt({required DateTime expiresAt, String email = 'jorge@example.com'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final payload = {
    'sub': 'u1',
    'email': email,
    'role': 'USER',
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
  };
  return '${part({'alg': 'HS256'})}.${part(payload)}.signature';
}

void main() {
  late _MemoryTokenStore store;
  late _MockAuthRepository auth;

  ProviderContainer container() => ProviderContainer.test(
    overrides: [
      tokenStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(auth),
      clockProvider.overrideWithValue(() => _now),
    ],
  );

  setUp(() {
    store = _MemoryTokenStore();
    auth = _MockAuthRepository();
  });

  group('restore', () {
    test('a live token becomes the session', () async {
      store
        ..token = _jwt(expiresAt: _now.add(const Duration(hours: 5)))
        ..names['jorge@example.com'] = 'Jorge';
      final session = await container().read(sessionControllerProvider.future);
      expect(session?.email, 'jorge@example.com');
      expect(session?.firstNames, 'Jorge');
      expect(session?.remainingAt(_now), const Duration(hours: 5));
    });

    test('an expired token is dropped', () async {
      store.token = _jwt(expiresAt: _now.subtract(const Duration(minutes: 1)));
      final session = await container().read(sessionControllerProvider.future);
      expect(session, isNull);
      expect(store.token, isNull);
    });

    test('a corrupt token is dropped', () async {
      store.token = 'not-a-jwt';
      final session = await container().read(sessionControllerProvider.future);
      expect(session, isNull);
      expect(store.token, isNull);
    });
  });

  group('login', () {
    test('stores the token and opens the session', () async {
      final token = _jwt(expiresAt: _now.add(const Duration(hours: 24)));
      store.names['jorge@example.com'] = 'Jorge';
      when(
        () => auth.login(email: 'Jorge@example.com', password: 'secreta1'),
      ).thenAnswer(
        (_) async =>
            LoginResponse(id: 'u1', email: 'jorge@example.com', token: token),
      );
      final ref = container();
      await ref.read(sessionControllerProvider.future);

      await ref
          .read(sessionControllerProvider.notifier)
          .login(email: 'Jorge@example.com', password: 'secreta1');

      expect(store.token, token);
      final session = ref.read(sessionControllerProvider).value;
      expect(session?.email, 'jorge@example.com');
      expect(session?.firstNames, 'Jorge');
    });

    test('a failure reaches the caller and opens nothing', () async {
      when(
        () => auth.login(
          email: any(named: 'email'),
          password: 'mala',
        ),
      ).thenThrow(const AppFailure.unauthorized());
      final ref = container();
      await ref.read(sessionControllerProvider.future);

      await expectLater(
        ref
            .read(sessionControllerProvider.notifier)
            .login(email: 'jorge@example.com', password: 'mala'),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(ref.read(sessionControllerProvider).value, isNull);
      expect(store.token, isNull);
    });
  });

  test('register stores the first names and logs in', () async {
    final token = _jwt(expiresAt: _now.add(const Duration(hours: 24)));
    when(
      () => auth.register(
        documentNumber: '1032456789',
        firstNames: 'Jorge',
        lastNames: 'Palacio',
        email: 'Jorge@example.com',
        password: 'secreta1',
      ),
    ).thenAnswer(
      (_) async => const RegisteredUser(
        id: 'u1',
        documentNumber: '1032456789',
        firstNames: 'Jorge',
        lastNames: 'Palacio',
        email: 'jorge@example.com',
      ),
    );
    when(() => auth.login(email: 'jorge@example.com', password: 'secreta1'))
        .thenAnswer(
          (_) async =>
              LoginResponse(id: 'u1', email: 'jorge@example.com', token: token),
        );
    final ref = container();
    await ref.read(sessionControllerProvider.future);

    await ref
        .read(sessionControllerProvider.notifier)
        .register(
          documentNumber: '1032456789',
          firstNames: 'Jorge',
          lastNames: 'Palacio',
          email: 'Jorge@example.com',
          password: 'secreta1',
        );

    expect(store.names['jorge@example.com'], 'Jorge');
    expect(ref.read(sessionControllerProvider).value?.firstNames, 'Jorge');
  });

  group('ending the session', () {
    late ProviderContainer ref;

    setUp(() async {
      store.token = _jwt(expiresAt: _now.add(const Duration(hours: 5)));
      ref = container();
      await ref.read(sessionControllerProvider.future);
    });

    test('logout deletes the token', () async {
      await ref.read(sessionControllerProvider.notifier).logout();
      expect(store.token, isNull);
      expect(ref.read(sessionControllerProvider).value, isNull);
      expect(ref.read(sessionExpiredProvider), 0);
    });

    test('a rejected token ends the session and signals it once', () async {
      ref.read(sessionControllerProvider.notifier)
        ..onUnauthorized()
        ..onUnauthorized();
      await pumpEventQueue();
      expect(store.token, isNull);
      expect(ref.read(sessionControllerProvider).value, isNull);
      expect(ref.read(sessionExpiredProvider), 1);
    });
  });

  test('a 401 without a session raises nothing', () async {
    final ref = container();
    await ref.read(sessionControllerProvider.future);
    ref.read(sessionControllerProvider.notifier).onUnauthorized();
    expect(ref.read(sessionExpiredProvider), 0);
  });
}

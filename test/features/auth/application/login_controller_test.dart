import 'dart:async';
import 'dart:convert';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:ecoeats/features/auth/application/login_controller.dart';
import 'package:ecoeats/features/auth/data/auth_dtos.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

class _MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async => this.token = token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> readFirstNames(String email) async => null;

  @override
  Future<void> writeFirstNames(String email, String firstNames) async {}
}

const _email = 'jorge@example.com';
const _password = 'secreta1';

String _jwt(DateTime expiresAt) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final payload = {
    'sub': 'u1',
    'email': _email,
    'role': 'USER',
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
  };
  return '${part({'alg': 'HS256'})}.${part(payload)}.signature';
}

void main() {
  late _MockAuthRepository auth;
  late DateTime now;
  late ProviderContainer container;

  LoginController controller() =>
      container.read(loginControllerProvider.notifier);
  LoginState state() => container.read(loginControllerProvider);

  Future<void> submit() =>
      controller().submit(email: _email, password: _password);

  void loginAnswers(Future<LoginResponse> Function() answer) => when(
    () => auth.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) => answer());

  void loginFails(AppFailure failure) => when(
    () => auth.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenThrow(failure);

  int loginCalls() => verify(
    () => auth.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).callCount;

  LoginResponse response() => LoginResponse(
    id: 'u1',
    email: _email,
    token: _jwt(now.add(const Duration(hours: 24))),
  );

  setUp(() async {
    auth = _MockAuthRepository();
    now = DateTime.utc(2026, 10, 25, 12);
    // Listening keeps the auto-disposed controller alive between awaits.
    container = ProviderContainer.test(
      overrides: [
        tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
        authRepositoryProvider.overrideWithValue(auth),
        clockProvider.overrideWithValue(() => now),
      ],
    )..listen(loginControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
  });

  test('valid credentials sign in through the session', () async {
    final pending = Completer<LoginResponse>();
    loginAnswers(() => pending.future);

    final submitting = submit();
    expect(state().submitting, isTrue);

    pending.complete(response());
    await submitting;

    expect(state(), const LoginState(succeeded: true));
    expect(container.read(sessionControllerProvider).value?.email, _email);
    verify(() => auth.login(email: _email, password: _password)).called(1);
  });

  test('401 keeps the failure and allows another try', () async {
    loginFails(const AppFailure.unauthorized());

    await submit();

    expect(state().failure, isA<UnauthorizedFailure>());
    expect(state().succeeded, isFalse);
    expect(state().submitting, isFalse);
    expect(container.read(sessionControllerProvider).value, isNull);

    await submit();
    expect(loginCalls(), 2);
  });

  test('400 names the rejected fields', () async {
    loginFails(
      const AppFailure.validation(
        fieldErrors: {'email': 'El email debe ser válido'},
      ),
    );
    await submit();
    expect(state().rejectedFields, {LoginField.email});

    loginFails(
      const AppFailure.validation(
        fieldErrors: {
          'email': 'El email debe ser válido',
          'password': 'La contraseña es obligatoria',
        },
      ),
    );
    await submit();
    expect(state().rejectedFields, {LoginField.email, LoginField.password});
  });

  test('other failures name no field', () async {
    loginFails(const AppFailure.unauthorized());
    await submit();
    expect(state().rejectedFields, isEmpty);
  });

  test('429 waits until Retry-After before sending again', () async {
    loginFails(const AppFailure.rateLimited(retryAfter: Duration(seconds: 42)));

    await submit();

    expect(state().failure, isA<RateLimitedFailure>());
    expect(state().blockedUntil, now.add(const Duration(seconds: 42)));

    now = now.add(const Duration(seconds: 41));
    await submit();
    expect(loginCalls(), 1);

    loginAnswers(() async => response());
    now = now.add(const Duration(seconds: 1));
    await submit();
    expect(loginCalls(), 1);
    expect(state().succeeded, isTrue);
  });

  test('a submit while one runs sends nothing', () async {
    final pending = Completer<LoginResponse>();
    loginAnswers(() => pending.future);

    final first = submit();
    await submit();
    pending.complete(response());
    await first;

    expect(loginCalls(), 1);
  });

  test('dismissing clears the failure but not the 429 wait', () async {
    loginFails(const AppFailure.unauthorized());
    await submit();
    controller().dismissFailure();
    expect(state().failure, isNull);

    loginFails(const AppFailure.rateLimited(retryAfter: Duration(seconds: 30)));
    await submit();
    controller().dismissFailure();
    expect(state().failure, isNull);
    expect(state().blockedUntil, now.add(const Duration(seconds: 30)));
  });
}

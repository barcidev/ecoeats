import 'dart:async';
import 'dart:convert';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:ecoeats/features/auth/application/register_controller.dart';
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

const _email = 'jorge@example.com';

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
  late _MemoryTokenStore store;
  late DateTime now;
  late ProviderContainer container;

  RegisterController controller() =>
      container.read(registerControllerProvider.notifier);
  RegisterState state() => container.read(registerControllerProvider);

  Future<void> submit() => controller().submit(
    documentNumber: '1032456789',
    firstNames: 'Jorge',
    lastNames: 'Palacio',
    email: _email,
    password: 'secreta1',
  );

  void registerAnswers(Future<RegisteredUser> Function() answer) => when(
    () => auth.register(
      documentNumber: any(named: 'documentNumber'),
      firstNames: any(named: 'firstNames'),
      lastNames: any(named: 'lastNames'),
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) => answer());

  void registerFails(AppFailure failure) => registerAnswers(() async {
    throw failure;
  });

  int registerCalls() => verify(
    () => auth.register(
      documentNumber: any(named: 'documentNumber'),
      firstNames: any(named: 'firstNames'),
      lastNames: any(named: 'lastNames'),
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).callCount;

  const user = RegisteredUser(
    id: 'u1',
    documentNumber: '1032456789',
    firstNames: 'Jorge',
    lastNames: 'Palacio',
    email: _email,
  );

  setUp(() async {
    auth = _MockAuthRepository();
    store = _MemoryTokenStore();
    now = DateTime.utc(2026, 10, 25, 12);
    // Listening keeps the auto-disposed controller alive between awaits.
    container = ProviderContainer.test(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(auth),
        clockProvider.overrideWithValue(() => now),
      ],
    )..listen(registerControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    when(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => LoginResponse(
        id: 'u1',
        email: _email,
        token: _jwt(now.add(const Duration(hours: 24))),
      ),
    );
  });

  test('moves between the two steps', () {
    expect(state().step, RegisterStep.about);
    controller().next();
    expect(state().step, RegisterStep.access);
    controller().back();
    expect(state().step, RegisterStep.about);
  });

  test('a created account signs in and keeps the first names', () async {
    controller().next();
    final pending = Completer<RegisteredUser>();
    registerAnswers(() => pending.future);

    final submitting = submit();
    expect(state().submitting, isTrue);
    pending.complete(user);
    await submitting;

    expect(state().succeeded, isTrue);
    expect(state().submitting, isFalse);
    final session = container.read(sessionControllerProvider).value;
    expect(session?.email, _email);
    expect(session?.firstNames, 'Jorge');
    expect(store.names[_email], 'Jorge');
  });

  test('a taken document goes back to step 1 and names its field', () async {
    controller().next();
    registerFails(const AppFailure.conflict(field: .document));

    await submit();

    expect(state().step, RegisterStep.about);
    expect(state().rejectedFields, {RegisterField.documentNumber});
    expect(state().succeeded, isFalse);
  });

  test('a taken email stays on step 2 and names its field', () async {
    controller().next();
    registerFails(const AppFailure.conflict(field: .email));

    await submit();

    expect(state().step, RegisterStep.access);
    expect(state().rejectedFields, {RegisterField.email});
  });

  test('a 400 lands on the first step that holds a refused field', () async {
    controller().next();
    registerFails(
      const AppFailure.validation(
        fieldErrors: {
          'nombres': 'Los nombres son obligatorios',
          'correo': 'El correo debe ser válido',
        },
      ),
    );

    await submit();

    expect(state().step, RegisterStep.about);
    expect(state().rejectedFields, {
      RegisterField.firstNames,
      RegisterField.email,
    });
    expect(
      state().serverMessage(RegisterField.firstNames),
      'Los nombres son obligatorios',
    );
    expect(state().serverMessage(RegisterField.lastNames), isNull);
  });

  test('a failure about no field stays where it is', () async {
    controller().next();
    registerFails(const AppFailure.offline());

    await submit();

    expect(state().step, RegisterStep.access);
    expect(state().failure, isA<OfflineFailure>());
    expect(state().rejectedFields, isEmpty);
  });

  test('429 waits until Retry-After before sending again', () async {
    controller().next();
    registerFails(
      const AppFailure.rateLimited(retryAfter: Duration(seconds: 30)),
    );
    await submit();
    expect(state().blockedUntil, now.add(const Duration(seconds: 30)));

    await submit();
    expect(registerCalls(), 1);

    now = now.add(const Duration(seconds: 30));
    registerAnswers(() async => user);
    await submit();
    expect(registerCalls(), 1);
    expect(state().succeeded, isTrue);
  });

  test('a submit while one runs sends nothing', () async {
    controller().next();
    final pending = Completer<RegisteredUser>();
    registerAnswers(() => pending.future);

    final first = submit();
    await submit();
    pending.complete(user);
    await first;

    expect(registerCalls(), 1);
  });

  test('dismissing clears the failure', () async {
    controller().next();
    registerFails(const AppFailure.conflict(field: .email));
    await submit();

    controller().dismissFailure();

    expect(state().failure, isNull);
    expect(state().rejectedFields, isEmpty);
  });
}

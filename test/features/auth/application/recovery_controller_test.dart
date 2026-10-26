import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/features/auth/application/clock.dart';
import 'package:ecoeats/features/auth/application/recovery_controller.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

const _email = 'jorge@example.com';

void main() {
  late _MockAuthRepository repository;
  late DateTime now;
  late ProviderContainer container;

  RecoveryController controller() =>
      container.read(recoveryControllerProvider.notifier);
  RecoveryState state() => container.read(recoveryControllerProvider);

  void codeIsSent() =>
      when(() => repository.forgotPassword(any())).thenAnswer((_) async {});

  void codeIs({required bool valid}) => when(
    () => repository.verifyOtp(
      email: any(named: 'email'),
      otp: any(named: 'otp'),
    ),
  ).thenAnswer((_) async => valid);

  void resetFails(AppFailure failure) => when(
    () => repository.resetPassword(
      email: any(named: 'email'),
      otp: any(named: 'otp'),
      newPassword: any(named: 'newPassword'),
    ),
  ).thenThrow(failure);

  Future<RecoveryCode> onCodeStep() async {
    codeIsSent();
    await controller().sendCode(' Jorge@Example.com ');
    return state() as RecoveryCode;
  }

  Future<RecoveryPassword> onPasswordStep() async {
    await onCodeStep();
    codeIs(valid: true);
    await controller().verify('123456');
    return state() as RecoveryPassword;
  }

  setUp(() {
    repository = _MockAuthRepository();
    now = DateTime(2026, 10, 25, 9);
    // Listening keeps the auto-disposed controller alive between awaits.
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    )..listen(recoveryControllerProvider, (_, _) {});
  });

  test('starts on the email step', () {
    expect(state(), const RecoveryState.email());
  });

  group('email step', () {
    test('a sent code opens the code step with its deadlines', () async {
      final code = await onCodeStep();

      verify(() => repository.forgotPassword(' Jorge@Example.com ')).called(1);
      expect(code.email, _email);
      expect(code.expiresAt, now.add(const Duration(minutes: 15)));
      expect(code.resendAt, now.add(const Duration(seconds: 60)));
      expect(code.attemptsLeft, 5);
      expect(code.issue, isNull);
    });

    test('an unknown email stays on the step with the failure', () async {
      when(() => repository.forgotPassword(any()))
          .thenThrow(const AppFailure.notFound());

      await controller().sendCode(_email);

      expect(
        state(),
        const RecoveryState.email(
          email: _email,
          failure: AppFailure.notFound(),
        ),
      );
    });

    test('a server failure can be retried', () async {
      when(() => repository.forgotPassword(any()))
          .thenThrow(const AppFailure.server(status: 503));
      await controller().sendCode(_email);
      expect((state() as RecoveryEmail).failure, isA<ServerFailure>());

      codeIsSent();
      await controller().sendCode(_email);
      expect(state(), isA<RecoveryCode>());
    });

    test('429 blocks the step until Retry-After passes', () async {
      when(() => repository.forgotPassword(any())).thenThrow(
        const AppFailure.rateLimited(retryAfter: Duration(seconds: 42)),
      );

      await controller().sendCode(_email);

      final email = state() as RecoveryEmail;
      expect(email.failure, isA<RateLimitedFailure>());
      expect(email.blockedUntil, now.add(const Duration(seconds: 42)));
    });
  });

  group('code step', () {
    test('a valid code opens the new password step', () async {
      final password = await onPasswordStep();

      verify(() => repository.verifyOtp(email: _email, otp: '123456'))
          .called(1);
      expect(password.email, _email);
      expect(password.code, '123456');
    });

    test('a rejected code costs one attempt', () async {
      await onCodeStep();
      codeIs(valid: false);

      await controller().verify('111111');

      final code = state() as RecoveryCode;
      expect(code.issue, CodeIssue.rejected);
      expect(code.attemptsLeft, 4);
      expect(code.verifying, isFalse);
    });

    test('the fifth rejection locks the code', () async {
      await onCodeStep();
      codeIs(valid: false);

      for (var i = 0; i < 5; i++) {
        await controller().verify('111111');
      }
      expect((state() as RecoveryCode).issue, CodeIssue.locked);
      expect((state() as RecoveryCode).attemptsLeft, 0);

      await controller().verify('123456');
      verify(
        () => repository.verifyOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).called(5);
    });

    test('a code past its deadline expires without asking', () async {
      await onCodeStep();
      now = now.add(const Duration(minutes: 15));

      await controller().verify('123456');

      expect((state() as RecoveryCode).issue, CodeIssue.expired);
      verifyNever(
        () => repository.verifyOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      );
    });

    test('a rejection after the deadline reads as expired', () async {
      await onCodeStep();
      codeIs(valid: false);
      when(
        () => repository.verifyOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async {
        now = now.add(const Duration(minutes: 16));
        return false;
      });

      await controller().verify('123456');

      expect((state() as RecoveryCode).issue, CodeIssue.expired);
    });

    test('resend waits 60 s', () async {
      await onCodeStep();
      now = now.add(const Duration(seconds: 59));

      await controller().resend();

      verify(() => repository.forgotPassword(any())).called(1);
    });

    test('resend after 60 s starts the code over', () async {
      await onCodeStep();
      codeIs(valid: false);
      await controller().verify('111111');
      now = now.add(const Duration(seconds: 60));

      await controller().resend();

      verify(() => repository.forgotPassword(any())).called(2);
      final code = state() as RecoveryCode;
      expect(code.expiresAt, now.add(const Duration(minutes: 15)));
      expect(code.resendAt, now.add(const Duration(seconds: 60)));
      expect(code.attemptsLeft, 5);
      expect(code.issue, isNull);
    });

    test('429 keeps the code and blocks until Retry-After', () async {
      await onCodeStep();
      when(
        () => repository.verifyOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(
        const AppFailure.rateLimited(retryAfter: Duration(seconds: 30)),
      );

      await controller().verify('123456');

      final code = state() as RecoveryCode;
      expect(code.failure, isA<RateLimitedFailure>());
      expect(code.blockedUntil, now.add(const Duration(seconds: 30)));
      expect(code.attemptsLeft, 5);

      await controller().verify('123456');
      verify(
        () => repository.verifyOtp(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).called(1);
    });

    test('back returns to the email step with the email filled', () async {
      await onCodeStep();

      controller().back();

      expect(state(), const RecoveryState.email(email: _email));
    });
  });

  group('new password step', () {
    test('an accepted password ends the flow', () async {
      await onPasswordStep();
      when(
        () => repository.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      await controller().resetPassword(' nueva clave');

      verify(
        () => repository.resetPassword(
          email: _email,
          otp: '123456',
          newPassword: ' nueva clave',
        ),
      ).called(1);
      expect(state(), const RecoveryState.done(email: _email));
    });

    test(
      'a code the reset no longer takes goes back to the code step',
      () async {
        final password = await onPasswordStep();
        resetFails(const AppFailure.validation(fieldErrors: {}));

        await controller().resetPassword('nueva clave');

        final code = state() as RecoveryCode;
        expect(code.email, _email);
        expect(code.issue, CodeIssue.expired);
        expect(code.resendAt, password.resendAt);
      },
    );

    test('a password the API rejects stays with its field errors', () async {
      await onPasswordStep();
      const failure = AppFailure.validation(
        fieldErrors: {'newPassword': 'La nueva contraseña es muy corta'},
      );
      resetFails(failure);

      await controller().resetPassword('corta');

      final password = state() as RecoveryPassword;
      expect(password.failure, failure);
      expect(password.saving, isFalse);
    });

    test('a code past its deadline goes back without asking', () async {
      await onPasswordStep();
      now = now.add(const Duration(minutes: 15));

      await controller().resetPassword('nueva clave');

      expect((state() as RecoveryCode).issue, CodeIssue.expired);
      verifyNever(
        () => repository.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test('back returns to the code step', () async {
      await onPasswordStep();

      controller().back();

      final code = state() as RecoveryCode;
      expect(code.email, _email);
      expect(code.issue, isNull);
    });
  });
}

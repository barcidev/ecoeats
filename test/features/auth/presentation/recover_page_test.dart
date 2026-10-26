import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/features/auth/presentation/widgets/otp_field.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

const _email = 'jorge@example.com';

void main() {
  late _MockAuthRepository auth;
  late DateTime now;

  setUp(() {
    auth = _MockAuthRepository();
    now = DateTime.utc(2026, 10, 25, 12);
    when(() => auth.forgotPassword(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  void codeIs({required bool valid}) => when(
    () => auth.verifyOtp(
      email: any(named: 'email'),
      otp: any(named: 'otp'),
    ),
  ).thenAnswer((_) async => valid);

  // The countdowns tick each second while the fake clock stands still, so
  // these tests pump fixed frames instead of settling.
  Future<void> frames(WidgetTester tester, [int count = 6]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpRecover(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          clockProvider.overrideWithValue(() => now),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: ecoTheme(.light),
            home: const RecoverPage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> sendCode(WidgetTester tester, [String email = _email]) async {
    await tester.enterText(find.byType(EditableText), email);
    await tester.tap(find.text('Enviar código'));
    await frames(tester);
  }

  Future<void> typeCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(EditableText), code);
    await frames(tester);
  }

  group('email step', () {
    testWidgets('a malformed email is refused on its field', (tester) async {
      await pumpRecover(tester);
      await sendCode(tester, 'jorge@');

      expect(
        find.text('Revisa el correo; parece que le falta algo.'),
        findsOneWidget,
      );
      verifyNever(() => auth.forgotPassword(any()));
    });

    testWidgets('an unknown email says so on its field', (tester) async {
      when(() => auth.forgotPassword(any()))
          .thenThrow(const AppFailure.notFound());
      await pumpRecover(tester);
      await sendCode(tester);

      expect(find.text('No hay ninguna cuenta con ese correo.'), findsOne);
    });

    testWidgets('a server failure shows its words and can be retried', (
      tester,
    ) async {
      when(() => auth.forgotPassword(any()))
          .thenThrow(const AppFailure.server(status: 503));
      await pumpRecover(tester);
      await sendCode(tester);
      expect(find.text('Algo se nos quemó en la cocina.'), findsOneWidget);

      when(() => auth.forgotPassword(any())).thenAnswer((_) async {});
      await tester.tap(find.text('Enviar código'));
      await frames(tester);
      expect(find.text('Revisa tu correo.'), findsOneWidget);
    });
  });

  group('code step', () {
    testWidgets('shows where the code went and both countdowns', (
      tester,
    ) async {
      await pumpRecover(tester);
      await sendCode(tester);

      expect(maskEmail(_email), 'j•••@example.com');
      expect(
        find.text('Escribe el código que enviamos a j•••@example.com.'),
        findsOneWidget,
      );
      expect(find.text('Vence en 15:00'), findsOneWidget);
      expect(find.text('Otro código en 1:00'), findsOneWidget);

      now = now.add(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 1));
      // The countdown reports its end after the frame; the link comes next.
      await tester.pump();
      expect(find.text('Vence en 14:00'), findsOneWidget);

      await tester.tap(find.text('Enviar otro código'));
      await frames(tester);
      verify(() => auth.forgotPassword(_email)).called(2);
      expect(find.text('Te enviamos un código nuevo.'), findsOneWidget);
      expect(find.text('Vence en 15:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a rejected code shakes, clears and counts the attempts', (
      tester,
    ) async {
      codeIs(valid: false);
      await pumpRecover(tester);
      await sendCode(tester);
      await typeCode(tester, '111111');

      expect(
        find.text('Ese código no coincide. Te quedan 4 intentos.'),
        findsOneWidget,
      );
      expect(tester.widget<Shake>(find.byType(Shake)).trigger, isNotNull);
      expect(tester.widget<OtpField>(find.byType(OtpField)).error, isTrue);
    });

    testWidgets('a code past its deadline asks for a new one', (tester) async {
      await pumpRecover(tester);
      await sendCode(tester);

      now = now.add(const Duration(minutes: 15));
      await tester.pump(const Duration(seconds: 1));
      await frames(tester, 2);

      expect(find.text('El código venció. Pide uno nuevo.'), findsOneWidget);
      expect(tester.widget<OtpField>(find.byType(OtpField)).enabled, isFalse);
    });
  });

  group('new password step', () {
    Future<void> onPasswordStep(WidgetTester tester) async {
      codeIs(valid: true);
      await pumpRecover(tester);
      await sendCode(tester);
      await typeCode(tester, '123456');
    }

    testWidgets('a different confirmation is refused on its field', (
      tester,
    ) async {
      await onPasswordStep(tester);
      expect(find.text('Elige tu contraseña nueva.'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).at(0), 'nueva clave');
      await tester.enterText(find.byType(EditableText).at(1), 'nueva clav');
      await tester.tap(find.text('Guardar contraseña'));
      await frames(tester);

      expect(find.text('No coincide con la contraseña.'), findsOneWidget);
      verifyNever(
        () => auth.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWidgets('a code the reset no longer takes goes back to step 2', (
      tester,
    ) async {
      when(
        () => auth.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(const AppFailure.validation(fieldErrors: {}));
      await onPasswordStep(tester);
      await tester.enterText(find.byType(EditableText).at(0), 'nueva clave');
      await tester.enterText(find.byType(EditableText).at(1), 'nueva clave');
      await tester.tap(find.text('Guardar contraseña'));
      await frames(tester);

      expect(find.text('Revisa tu correo.'), findsOneWidget);
      expect(find.text('El código venció. Pide uno nuevo.'), findsOneWidget);
    });

    testWidgets('a saved password draws the check', (tester) async {
      when(
        () => auth.resetPassword(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});
      await onPasswordStep(tester);
      await tester.enterText(find.byType(EditableText).at(0), 'nueva clave');
      await tester.enterText(find.byType(EditableText).at(1), 'nueva clave');
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();

      verify(
        () => auth.resetPassword(
          email: _email,
          otp: '123456',
          newPassword: 'nueva clave',
        ),
      ).called(1);
      expect(find.text('Listo.'), findsOneWidget);
      expect(find.text('Ir a entrar'), findsOneWidget);
      expect(find.byKey(RecoverPage.checkKey), findsOneWidget);
    });
  });

  testWidgets('with reduced motion the check is already drawn', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    codeIs(valid: true);
    when(
      () => auth.resetPassword(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});
    await pumpRecover(tester);
    await sendCode(tester);
    await typeCode(tester, '123456');
    await tester.enterText(find.byType(EditableText).at(0), 'nueva clave');
    await tester.enterText(find.byType(EditableText).at(1), 'nueva clave');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pump();
    await tester.pump();

    final drawing = tester.widget<TweenAnimationBuilder<double>>(
      find.ancestor(
        of: find.byKey(RecoverPage.checkKey),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    );
    expect(drawing.tween.begin, 1);
  });
}

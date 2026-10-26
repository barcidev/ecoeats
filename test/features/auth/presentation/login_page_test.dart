import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/core/session/sign_in_hold.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/features/auth/presentation/widgets/achiote_sweep.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:ecoeats/router/guards.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

class _FakeSession extends SessionController {
  /// What the API does with the next login; it succeeds when null.
  Future<void> Function()? answer;
  final logins = <(String, String)>[];

  @override
  Future<Session?> build() async => null;

  @override
  Future<void> login({required String email, required String password}) async {
    logins.add((email, password));
    await answer?.call();
  }
}

Future<void> Function() _fails(AppFailure failure) =>
    () async => throw failure;

const _email = 'jorge@example.com';

void main() {
  late _FakeSession session;
  late DateTime now;
  late List<MethodCall> platform;

  setUp(() {
    session = _FakeSession();
    now = DateTime.utc(2026, 10, 25, 12);
    platform = [];
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  List<Override> overrides() => [
    sessionControllerProvider.overrideWith(() => session),
    clockProvider.overrideWithValue(() => now),
  ];

  void recordPlatform(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platform.add(call);
        return null;
      },
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      (call) async {
        platform.add(call);
        return null;
      },
    );
  }

  Future<void> pumpLogin(WidgetTester tester) async {
    recordPlatform(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: TranslationProvider(
          child: MaterialApp(theme: ecoTheme(.light), home: const LoginPage()),
        ),
      ),
    );
    await tester.pump();
  }

  Finder field(int index) => find.byType(EditableText).at(index);

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(field(0), email);
    await tester.enterText(field(1), password);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  Object? shakes(WidgetTester tester) =>
      tester.widget<Shake>(find.byType(Shake)).trigger;

  bool vibrated() =>
      platform.any((call) => call.method == 'HapticFeedback.vibrate');

  SignInHold holdOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(LoginPage)))
          .read(signInHoldProvider);

  group('before sending', () {
    testWidgets('empty fields refuse with a shake and send nothing', (
      tester,
    ) async {
      await pumpLogin(tester);
      expect(find.text('Escribe tu correo.'), findsNothing);

      await submit(tester);

      expect(find.text('Escribe tu correo.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);
      expect(session.logins, isEmpty);
      expect(shakes(tester), isNotNull);
      expect(vibrated(), isTrue);
    });

    testWidgets('a field message follows the typing after the first try', (
      tester,
    ) async {
      await pumpLogin(tester);
      await fill(tester, 'jorge@', 'secreta1');
      await submit(tester);
      expect(
        find.text('Revisa el correo; parece que le falta algo.'),
        findsOneWidget,
      );

      await tester.enterText(field(0), _email);
      await tester.pump();
      expect(
        find.text('Revisa el correo; parece que le falta algo.'),
        findsNothing,
      );
    });

    testWidgets('offers autofill and shows the password on demand', (
      tester,
    ) async {
      await pumpLogin(tester);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(
        fields[0].autofillHints,
        containsAll([AutofillHints.email, AutofillHints.username]),
      );
      expect(fields[1].autofillHints, contains(AutofillHints.password));
      expect(tester.widget<EditableText>(field(1)).obscureText, isTrue);

      await tester.tap(find.byIcon(EcoIcons.eye));
      await tester.pump();
      expect(tester.widget<EditableText>(field(1)).obscureText, isFalse);
    });
  });

  group('the answer', () {
    testWidgets('401 says so under the form and shakes', (tester) async {
      session.answer = _fails(const AppFailure.unauthorized());
      await pumpLogin(tester);
      await fill(tester, _email, 'mala');
      await submit(tester);

      expect(session.logins, [(_email, 'mala')]);
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(shakes(tester), isNotNull);
      expect(vibrated(), isTrue);

      await tester.enterText(field(1), 'secreta1');
      await tester.pump();
      expect(find.text('Correo o contraseña incorrectos.'), findsNothing);
    });

    testWidgets('400 puts each message on its field', (tester) async {
      session.answer = _fails(
        const AppFailure.validation(
          fieldErrors: {'email': 'El email debe ser válido'},
        ),
      );
      await pumpLogin(tester);
      await fill(tester, _email, 'secreta1');
      await submit(tester);

      expect(
        find.text('Revisa el correo; parece que le falta algo.'),
        findsOneWidget,
      );
      expect(find.text('El email debe ser válido'), findsNothing);
    });

    testWidgets('a lost connection shows its words without shaking', (
      tester,
    ) async {
      session.answer = _fails(const AppFailure.offline());
      await pumpLogin(tester);
      await fill(tester, _email, 'secreta1');
      await submit(tester);

      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(shakes(tester), isNull);
    });

    testWidgets('429 counts down on the button and works again at zero', (
      tester,
    ) async {
      session.answer = _fails(
        const AppFailure.rateLimited(retryAfter: Duration(seconds: 3)),
      );
      await pumpLogin(tester);
      await fill(tester, _email, 'secreta1');
      // The countdown ticks each second while the fake clock stands still, so
      // this screen never settles: pump instead.
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Intenta en 0:03'), findsOneWidget);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Intenta en 0:02'), findsOneWidget);

      await tester.tap(find.text('Intenta en 0:02'));
      await tester.pump();
      expect(session.logins, hasLength(1));

      session.answer = null;
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Entrar'), findsOneWidget);

      await submit(tester);
      expect(session.logins, hasLength(2));
    });

    testWidgets('success draws the check, then sweeps from it and lets Home '
        'come once covered', (tester) async {
      session.answer = () =>
          Future<void>.delayed(const Duration(milliseconds: 50));
      await pumpLogin(tester);
      await fill(tester, _email, 'secreta1');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.byType(PlateSpinner), findsOneWidget);
      var home = false;
      unawaited(holdOf(tester).wait().then((_) => home = true));

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(find.byKey(EcoButton.checkKey), findsOneWidget);
      expect(find.byKey(AchioteSweep.key), findsNothing);

      // The check takes 760 ms; the sweep is born once it is drawn.
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(AchioteSweep.key), findsOneWidget);
      expect(
        platform.map((call) => call.method),
        contains('TextInput.finishAutofillContext'),
      );
      expect(home, isFalse);

      await tester.pump(const Duration(milliseconds: 600));
      expect(home, isTrue);

      await tester.pumpAndSettle();
      expect(find.byKey(AchioteSweep.key), findsNothing);
    });

    testWidgets('a refused sign-in lets Home go without waiting', (
      tester,
    ) async {
      session.answer = _fails(const AppFailure.unauthorized());
      await pumpLogin(tester);
      await fill(tester, _email, 'mala');
      await submit(tester);

      var home = false;
      unawaited(holdOf(tester).wait().then((_) => home = true));
      await tester.pump();
      expect(home, isTrue);
    });

    testWidgets('with reduced motion a success does not sweep and a refusal '
        'still vibrates', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await pumpLogin(tester);
      await submit(tester);
      expect(vibrated(), isTrue);

      await fill(tester, _email, 'secreta1');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AchioteSweep.key), findsNothing);
      var home = false;
      unawaited(holdOf(tester).wait().then((_) => home = true));
      await tester.pump();
      expect(home, isTrue);
    });
  });

  testWidgets('links open recovery over login and swap login for '
      'registration', (tester) async {
    final router = AppRouter(
      authGuard: AuthGuard(isSignedIn: () => false),
      guestGuard: GuestGuard(isSignedIn: () => false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: ecoTheme(.light),
            routerConfig: router.config(
              deepLinkBuilder: (_) => const DeepLink([
                AuthShellRoute(children: [LoginRoute()]),
              ]),
            ),
          ),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(Motion.slow ~/ 4);
      }
    }

    await settle();
    expect(find.text('Hola otra vez.'), findsOneWidget);

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await settle();
    expect(find.text('Recupera tu contraseña.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Volver').last);
    await settle();
    await tester.tap(find.text('Crear una'));
    await settle();
    expect(find.text('Crea tu cuenta.'), findsOneWidget);
    final shell = router.innerRouterOf<StackRouter>(AuthShellRoute.name)!;
    expect(shell.stack.map((page) => page.name), isNot(contains('LoginRoute')));
  });

  testWidgets('recovery hands its email back to login', (tester) async {
    final auth = _MockAuthRepository();
    when(() => auth.forgotPassword(any())).thenAnswer((_) async {});
    when(
      () => auth.verifyOtp(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => auth.resetPassword(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});
    final router = AppRouter(
      authGuard: AuthGuard(isSignedIn: () => false),
      guestGuard: GuestGuard(isSignedIn: () => false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides(),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: ecoTheme(.light),
            routerConfig: router.config(
              deepLinkBuilder: (_) => const DeepLink([
                AuthShellRoute(children: [LoginRoute()]),
              ]),
            ),
          ),
        ),
      ),
    );
    Future<void> frames() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(Motion.slow ~/ 4);
      }
    }

    await frames();
    await tester.enterText(field(1), 'vieja');
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await frames();
    await tester.enterText(field(0), _email);
    await tester.tap(find.text('Enviar código'));
    await frames();
    await tester.enterText(field(0), '123456');
    await frames();
    await tester.enterText(field(0), 'nueva clave');
    await tester.enterText(field(1), 'nueva clave');
    await tester.tap(find.text('Guardar contraseña'));
    await frames();
    await tester.tap(find.text('Ir a entrar'));
    await frames();

    expect(find.text('Hola otra vez.'), findsOneWidget);
    expect(tester.widget<EditableText>(field(0)).controller.text, _email);
    expect(tester.widget<EditableText>(field(1)).controller.text, isEmpty);
  });
}

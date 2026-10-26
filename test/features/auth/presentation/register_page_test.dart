import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/shake.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/features/auth/presentation/widgets/achiote_sweep.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeSession extends SessionController {
  /// What the API does with the next registration; it succeeds when null.
  Future<void> Function()? answer;
  final registrations = <List<String>>[];

  @override
  Future<Session?> build() async => null;

  @override
  Future<void> register({
    required String documentNumber,
    required String firstNames,
    required String lastNames,
    required String email,
    required String password,
  }) async {
    registrations.add([documentNumber, firstNames, lastNames, email, password]);
    await answer?.call();
  }
}

Future<void> Function() _fails(AppFailure failure) =>
    () async => throw failure;

void main() {
  late _FakeSession session;
  late DateTime now;

  setUp(() {
    session = _FakeSession();
    now = DateTime.utc(2026, 10, 25, 12);
  });

  Future<void> pumpRegister(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          clockProvider.overrideWithValue(() => now),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: ecoTheme(.light),
            home: const RegisterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder field(int index) => find.byType(EditableText).at(index);

  Future<void> tapAndSettle(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> fillAbout(WidgetTester tester) async {
    await tester.enterText(field(0), 'Jorge');
    await tester.enterText(field(1), 'Palacio');
    await tester.enterText(field(2), '1032456789');
    await tapAndSettle(tester, 'Continuar');
  }

  Future<void> fillAccess(
    WidgetTester tester, {
    String password = 'secreta1',
  }) async {
    await tester.enterText(field(0), 'jorge@example.com');
    await tester.enterText(field(1), password);
    await tester.pump();
  }

  Object? shakes(WidgetTester tester) =>
      tester.widget<Shake>(find.byType(Shake)).trigger;

  testWidgets('step 1 refuses blank fields with a shake and stays', (
    tester,
  ) async {
    await pumpRegister(tester);
    expect(find.text('PASO 1 DE 2'), findsOneWidget);

    await tapAndSettle(tester, 'Continuar');

    expect(find.text('Escribe tus nombres.'), findsOneWidget);
    expect(find.text('Escribe tus apellidos.'), findsOneWidget);
    expect(find.text('Escribe tu número de documento.'), findsOneWidget);
    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(shakes(tester), isNotNull);
  });

  testWidgets('step 2 opens after a valid step 1, and going back keeps what '
      'was typed', (tester) async {
    await pumpRegister(tester);
    await fillAbout(tester);

    expect(find.text('PASO 2 DE 2'), findsOneWidget);
    expect(find.text('Ahora, con qué vas a entrar.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('Jorge'), findsOneWidget);
    expect(find.text('1032456789'), findsOneWidget);
  });

  testWidgets('the checklist follows the password and a long one is not '
      'sent', (tester) async {
    await pumpRegister(tester);
    await fillAbout(tester);
    await fillAccess(tester, password: 'ñ' * 40);

    expect(find.bySemanticsLabel('No demasiado larga, Falta'), findsOne);

    await tapAndSettle(tester, 'Crear cuenta');
    expect(
      find.text('Es demasiado larga; las tildes y los emoji cuentan más.'),
      findsOneWidget,
    );
    expect(session.registrations, isEmpty);
  });

  testWidgets('a taken document goes back to step 1 and says so there', (
    tester,
  ) async {
    session.answer = _fails(const AppFailure.conflict(field: .document));
    await pumpRegister(tester);
    await fillAbout(tester);
    await fillAccess(tester);
    await tapAndSettle(tester, 'Crear cuenta');

    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('Ya hay una cuenta con ese documento.'), findsOneWidget);
    expect(shakes(tester), isNotNull);
  });

  testWidgets('a taken email stays on step 2 and says so there', (
    tester,
  ) async {
    session.answer = _fails(const AppFailure.conflict(field: .email));
    await pumpRegister(tester);
    await fillAbout(tester);
    await fillAccess(tester);
    await tapAndSettle(tester, 'Crear cuenta');

    expect(find.text('PASO 2 DE 2'), findsOneWidget);
    expect(find.text('Ya hay una cuenta con ese correo.'), findsOneWidget);
  });

  testWidgets('a 400 shows the server words on its field in Spanish', (
    tester,
  ) async {
    session.answer = _fails(
      const AppFailure.validation(
        fieldErrors: {'apellidos': 'Los apellidos no pueden superar 100'},
      ),
    );
    await pumpRegister(tester);
    await fillAbout(tester);
    await fillAccess(tester);
    await tapAndSettle(tester, 'Crear cuenta');

    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('Los apellidos no pueden superar 100'), findsOneWidget);
  });

  testWidgets('429 counts down on the button', (tester) async {
    session.answer = _fails(
      const AppFailure.rateLimited(retryAfter: Duration(seconds: 3)),
    );
    await pumpRegister(tester);
    await fillAbout(tester);
    await fillAccess(tester);
    // The countdown ticks while the fake clock stands still: pump instead
    // of settling.
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Intenta en 0:03'), findsOneWidget);
  });

  testWidgets('a created account sends everything and sweeps into Home', (
    tester,
  ) async {
    await pumpRegister(tester);
    await fillAbout(tester);
    await fillAccess(tester);
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();
    await tester.pump();

    expect(session.registrations, [
      ['1032456789', 'Jorge', 'Palacio', 'jorge@example.com', 'secreta1'],
    ]);
    expect(find.byKey(AchioteSweep.key), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/features/profile/application/locale_controller.dart';
import 'package:ecoeats/features/profile/application/theme_mode_controller.dart';
import 'package:ecoeats/features/profile/presentation/profile_sheet.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSession extends SessionController {
  new({this.initial, this.failure});

  final Session? initial;
  final AppFailure? failure;
  final logins = <(String, String)>[];
  int logouts = 0;

  @override
  Future<Session?> build() async => initial;

  @override
  Future<void> login({required String email, required String password}) async {
    logins.add((email, password));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (failure case final failure?) throw failure;
  }

  @override
  Future<void> logout() async {
    logouts++;
    state = const AsyncData(null);
  }
}

final _now = DateTime.utc(2026, 10, 25, 12);

Widget _app(_FakeSession session, Widget home) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(() => session),
    clockProvider.overrideWithValue(() => _now),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: ecoTheme(.light),
      home: Scaffold(body: home),
    ),
  ),
);

void main() {
  // The test device speaks English; the stored choice keeps these in Spanish.
  setUp(() {
    SharedPreferences.setMockInitialValues({'profile.language': 'spanish'});
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  group('login placeholder', () {
    testWidgets('sends what was typed and shows it is working', (tester) async {
      final session = _FakeSession();
      await tester.pumpWidget(_app(session, const LoginPage()));
      await tester.enterText(
        find.byType(EditableText).at(0),
        'jorge@example.com',
      );
      await tester.enterText(find.byType(EditableText).at(1), 'secreta1');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.byType(PlateSpinner), findsOneWidget);
      await tester.pumpAndSettle();
      expect(session.logins, [('jorge@example.com', 'secreta1')]);
    });

    testWidgets('wrong credentials show their own words', (tester) async {
      final session = _FakeSession(failure: const AppFailure.unauthorized());
      await tester.pumpWidget(_app(session, const LoginPage()));
      await tester.enterText(
        find.byType(EditableText).at(0),
        'jorge@example.com',
      );
      await tester.enterText(find.byType(EditableText).at(1), 'mala');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('ProfileSheet', () {
    final session = Session(
      token: 'jwt',
      userId: 'u1',
      email: 'jorge@example.com',
      firstNames: 'Jorge',
      expiresAt: _now.add(const Duration(hours: 23, minutes: 30)),
    );

    Future<void> open(WidgetTester tester, _FakeSession fake) async {
      await tester.pumpWidget(
        _app(
          fake,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileSheet.show(context),
              child: const Text('perfil'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('perfil'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows who is in and when the session ends', (tester) async {
      await open(tester, _FakeSession(initial: session));
      expect(find.text('Jorge'), findsOneWidget);
      expect(find.text('jorge@example.com'), findsOneWidget);
      expect(find.text('Tu sesión vence en 23 h'), findsOneWidget);
    });

    testWidgets('signs out and closes', (tester) async {
      final fake = _FakeSession(initial: session);
      await open(tester, fake);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      // Signing out asks first; the same words confirm it.
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(fake.logouts, 1);
      expect(find.text('jorge@example.com'), findsNothing);
    });

    testWidgets('cancelling the sign-out changes nothing', (tester) async {
      final fake = _FakeSession(initial: session);
      await open(tester, fake);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(fake.logouts, 0);
      expect(find.text('¿Cerrar sesión?'), findsNothing);
      expect(find.text('jorge@example.com'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('the last hour of a session reads as such', (tester) async {
      await open(
        tester,
        _FakeSession(
          initial: session.copyWith(
            firstNames: null,
            expiresAt: _now.add(const Duration(minutes: 40)),
          ),
        ),
      );

      expect(
        find.text('Tu sesión vence en menos de una hora.'),
        findsOneWidget,
      );
      expect(find.text('jorge@example.com'), findsOneWidget);
    });

    testWidgets('appearance and language change at once', (tester) async {
      await open(tester, _FakeSession(initial: session));
      final container = ProviderScope.containerOf(
        tester.element(find.text('Tu perfil')),
      );
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeControllerProvider).value, ThemeMode.dark);

      // English is a deferred library, which loads outside the fake clock.
      await tester.tap(find.text('English'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(localeControllerProvider).value,
        LocaleChoice.english,
      );
      expect(find.text('Your profile'), findsOneWidget);
    });
  });
}

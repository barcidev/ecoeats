import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/features/profile/presentation/profile_sheet.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
      expect(fake.logouts, 1);
      expect(find.text('jorge@example.com'), findsNothing);
    });
  });
}

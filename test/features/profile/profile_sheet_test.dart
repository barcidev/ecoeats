import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/features/auth/presentation/auth_pages.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeSession extends SessionController {
  new({this.failure});

  final AppFailure? failure;
  final logins = <(String, String)>[];
  int logouts = 0;

  @override
  Future<Session?> build() async => null;

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

Widget _app(_FakeSession session, Widget home) => ProviderScope(
  overrides: [sessionControllerProvider.overrideWith(() => session)],
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
}

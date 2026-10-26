import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/features/auth/presentation/widgets/password_checklist.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpRules(WidgetTester tester, String password) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: ecoTheme(.light),
          home: Scaffold(body: PasswordRules(password: password)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const hint = 'Las tildes y los emoji cuentan más.';

  testWidgets('an empty password still needs its length', (tester) async {
    await pumpRules(tester, '');

    expect(find.bySemanticsLabel('Al menos 6 caracteres, Falta'), findsOne);
    expect(find.bySemanticsLabel('No demasiado larga, Listo'), findsOne);
    expect(find.text(hint), findsNothing);
  });

  testWidgets('a good password meets both rules', (tester) async {
    await pumpRules(tester, 'Ejemplo123!');

    expect(find.bySemanticsLabel('Al menos 6 caracteres, Listo'), findsOne);
    expect(find.bySemanticsLabel('No demasiado larga, Listo'), findsOne);
  });

  testWidgets('a password past 72 bytes breaks the byte rule and explains '
      'why', (tester) async {
    await pumpRules(tester, 'ñ' * 40);

    expect(find.bySemanticsLabel('Al menos 6 caracteres, Listo'), findsOne);
    expect(find.bySemanticsLabel('No demasiado larga, Falta'), findsOne);
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('the hint shows as the password nears the limit', (tester) async {
    await pumpRules(tester, 'ñ' * 31);

    expect(find.bySemanticsLabel('No demasiado larga, Listo'), findsOne);
    expect(find.text(hint), findsOneWidget);
  });
}

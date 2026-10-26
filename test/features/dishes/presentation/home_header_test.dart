import 'package:ecoeats/features/dishes/presentation/home/home_greeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/app_harness.dart';

void main() {
  group('day parts', () {
    test('follow the Colombian day', () {
      expect(dayPartOf(DateTime(2026, 10, 24, 5)), DayPart.morning);
      expect(dayPartOf(DateTime(2026, 10, 24, 11, 59)), DayPart.morning);
      expect(dayPartOf(DateTime(2026, 10, 24, 12)), DayPart.afternoon);
      expect(dayPartOf(DateTime(2026, 10, 24, 18, 59)), DayPart.afternoon);
      expect(dayPartOf(DateTime(2026, 10, 24, 19)), DayPart.evening);
      expect(dayPartOf(DateTime(2026, 10, 24, 4, 59)), DayPart.evening);
    });

    test('only the first name greets', () {
      expect(firstNameOf('  Jorge Andrés '), 'Jorge');
      expect(firstNameOf(null), isNull);
      expect(firstNameOf('   '), isNull);
    });
  });

  testWidgets('the header greets by the time of day', (tester) async {
    await bootApp(tester);
    expect(find.text('SÁBADO 24 DE OCTUBRE'), findsOneWidget);
    expect(find.text('Buenos días, Jorge.'), findsOneWidget);
    expect(find.text('¿Qué desayunamos hoy?'), findsOneWidget);
  });

  testWidgets('the avatar opens the profile', (tester) async {
    await bootApp(tester);
    await tester.tap(find.bySemanticsLabel('Abrir tu perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Tu perfil'), findsOneWidget);
  });

  testWidgets('searching leaves only the results', (tester) async {
    await bootApp(tester);
    expect(find.text('Ajiaco Santafereño'), findsWidgets);

    await tester.enterText(find.byType(EditableText), 'camaron');
    await tester.pumpAndSettle();
    expect(find.text('Arroz con Camarones'), findsOneWidget);
    expect(find.text('Cazuela de Mariscos'), findsOneWidget);
    expect(find.text('Ajiaco Santafereño'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Ajiaco Santafereño'), findsWidgets);
  });
}

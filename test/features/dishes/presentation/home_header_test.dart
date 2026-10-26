import 'package:ecoeats/features/dishes/presentation/home/home_greeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/dish_fixtures.dart';

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

  testWidgets('the night has its own greeting', (tester) async {
    await bootApp(tester, now: DateTime(2026, 10, 24, 20));
    expect(find.text('Buenas noches, Jorge.'), findsOneWidget);
    expect(find.text('¿Qué se te antoja esta noche?'), findsOneWidget);
  });

  testWidgets('English reads the date and greeting its own way', (
    tester,
  ) async {
    await bootApp(tester, now: DateTime(2026, 10, 24, 13), locale: .en);
    expect(find.text('SATURDAY, OCTOBER 24'), findsOneWidget);
    expect(find.text('Good afternoon, Jorge.'), findsOneWidget);
    expect(find.text("What's for lunch today?"), findsOneWidget);
  });

  testWidgets('without a known name the greeting stands alone', (tester) async {
    await bootApp(tester, session: signedIn(firstNames: null));
    expect(find.text('Buenos días.'), findsOneWidget);
  });

  testWidgets('scrolling folds the masthead but keeps the search', (
    tester,
  ) async {
    final longMenu = [
      for (var round = 0; round < 4; round++)
        for (final dish in sampleDishes)
          dish.copyWith(id: '${dish.id}-$round', name: '${dish.name} $round'),
    ];
    await bootApp(tester, dishes: longMenu);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('SÁBADO 24 DE OCTUBRE'), findsNothing);
    expect(find.byType(EditableText).hitTestable(), findsOneWidget);
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

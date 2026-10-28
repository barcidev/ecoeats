import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/features/dishes/presentation/detail/dish_detail_page.dart';
import 'package:ecoeats/features/dishes/presentation/home/menu_filters.dart';
import 'package:ecoeats/features/profile/application/theme_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/dish_fixtures.dart';

final Finder _menu = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axisDirection == .down,
);

Future<void> _scrollTo(
  WidgetTester tester,
  Finder target, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(target, delta, scrollable: _menu.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a pill keeps only its category', (tester) async {
    await bootApp(tester);
    await _scrollTo(tester, find.text('Ligeros'));
    await tester.tap(find.text('Ligeros'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('6 platos'));
    expect(find.text('6 platos'), findsOneWidget);
  });

  testWidgets('the pills stay pinned while the menu scrolls', (tester) async {
    await bootApp(tester);
    await _scrollTo(tester, find.text('12 platos'));
    expect(find.text('Todos').hitTestable(), findsOneWidget);
  });

  testWidgets('the sort sheet reorders the menu and closes', (tester) async {
    await bootApp(tester);
    await _scrollTo(tester, find.text('Ligeros'));
    await tester.tap(find.bySemanticsLabel(RegExp('^Ordenar')));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar la carta'), findsOneWidget);

    await tester.tap(find.text('Más proteína'));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar la carta'), findsNothing);
    final bandeja = find.bySemanticsLabel(RegExp(r'^Bandeja Paisa\.'));
    final posta = find.bySemanticsLabel(RegExp(r'^Posta Negra Cartagenera\.'));
    await _scrollTo(tester, find.text('Posta Negra Cartagenera'), delta: -300);
    expect(
      tester.getTopLeft(bandeja).dy,
      lessThan(tester.getTopLeft(posta).dy),
    );
  });

  testWidgets('a row reads as one sentence and opens its dish', (tester) async {
    await bootApp(tester);
    final row = find.bySemanticsLabel(
      r'Ajiaco Santafereño. $ 24.000. Calificación 4,8. 38 g de proteína.',
    );
    await _scrollTo(tester, row);
    expect(find.text('Pollo, papa criolla, papa sabanera…'), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DishDetailPage),
        matching: find.text('Ajiaco Santafereño'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the colophon counts in each language', (tester) async {
    await bootApp(tester, locale: .en);
    await _scrollTo(tester, find.text('12 dishes'));
    expect(find.text('12 dishes'), findsOneWidget);
  });

  testWidgets('one dish is counted in the singular', (tester) async {
    await bootApp(tester, dishes: [sampleDish('mote')]);
    await _scrollTo(tester, find.text('1 plato'));
    expect(find.text('1 plato'), findsOneWidget);
  });

  testWidgets('pulling the menu down fetches it again', (tester) async {
    final arepa = sampleDish('mote')
        .copyWith(id: 'arepa', name: 'Arepa de Huevo');
    final repository = MockDishRepository();
    var calls = 0;
    when(repository.fetchAll).thenAnswer(
      (_) async => calls++ == 0 ? sampleDishes : [...sampleDishes, arepa],
    );
    await bootApp(tester, repository: repository);

    await tester.fling(_menu.first, const Offset(0, 500), 2000);
    await tester.pumpAndSettle();

    verify(repository.fetchAll).called(2);
    await _scrollTo(tester, find.text('13 platos'));
    expect(find.text('13 platos'), findsOneWidget);
  });
  testWidgets('AC1: switching theme updates the pinned filters background', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = await bootApp(tester);
    await _scrollTo(tester, find.text('Todos'));
    Finder headerBox() => find
        .descendant(
          of: find.byType(MenuFilters),
          matching: find.byType(DecoratedBox),
        )
        .first;

    expect(
      (tester.widget<DecoratedBox>(headerBox()).decoration as BoxDecoration)
          .color,
      EcoPalette.mantel.paper,
    );

    await container
        .read(themeModeControllerProvider.notifier)
        .choose(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(
      (tester.widget<DecoratedBox>(headerBox()).decoration as BoxDecoration)
          .color,
      EcoPalette.fogon.paper,
    );
  });
}

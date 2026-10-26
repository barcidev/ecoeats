import 'dart:async';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/presentation/detail/dish_detail_page.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/dish_fixtures.dart';

MockDishRepository _catalog({Future<Dish> Function(String id)? one}) {
  final repository = MockDishRepository();
  when(repository.fetchAll).thenAnswer((_) async => sampleDishes);
  when(() => repository.fetchOne(any())).thenAnswer((invocation) {
    final id = invocation.positionalArguments.first as String;
    return one?.call(id) ?? Future.value(sampleDish(id));
  });
  return repository;
}

Finder _inDetail(Finder finder) =>
    find.descendant(of: find.byType(DishDetailPage), matching: finder);

final Finder _detailScroll = _inDetail(
  find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axisDirection == .down,
  ),
);

Future<void> _openBandeja(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^Destacado 1 de 4')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a featured card opens the dish in full', (tester) async {
    await bootApp(tester, repository: _catalog());
    await _openBandeja(tester);

    expect(_inDetail(find.text('Bandeja Paisa')), findsOneWidget);
    expect(_inDetail(find.text('DESTACADO DE LA CASA')), findsOneWidget);
    expect(_inDetail(find.bySemanticsLabel('4,9 de 5')), findsOneWidget);
    expect(_inDetail(find.text(r'$ 28.000')), findsOneWidget);
    expect(
      _inDetail(find.text('Bandeja Paisa, como en casa.')),
      findsOneWidget,
    );
    expect(
      _inDetail(
        find.byWidgetPredicate(
          (widget) => widget is Hero && widget.tag == 'dish-bandeja-carousel',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the name flies with the photo into the headline', (
    tester,
  ) async {
    bool nameHero(Widget widget, String tag) =>
        widget is Hero && widget.tag == tag;

    await bootApp(tester, repository: _catalog());
    await tester.tap(find.bySemanticsLabel(RegExp('^Destacado 1 de 4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    // Mid-flight, the card's name and the headline cross in the overlay.
    expect(find.text('Bandeja Paisa'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(
      _inDetail(
        find.byWidgetPredicate(
          (widget) => nameHero(widget, 'dish-bandeja-carousel-name'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('macros and numbered ingredients', (tester) async {
    final container = await bootApp(tester, repository: _catalog());
    unawaited(
      container
          .read(appRouterProvider)
          .push(DishDetailRoute(id: 'arroz', initial: sampleDish('arroz'))),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      _inDetail(find.bySemanticsLabel('Carbohidratos, 60 g')),
      200,
      scrollable: _detailScroll,
    );
    expect(_inDetail(find.bySemanticsLabel('Proteínas, 30 g')), findsOneWidget);

    final hogao = _inDetail(find.text('hogao (tomate, cebolla)'));
    await tester.scrollUntilVisible(hogao, 200, scrollable: _detailScroll);
    expect(hogao, findsOneWidget);
    expect(_inDetail(find.text('04')), findsOneWidget);
    expect(_inDetail(find.text('05')), findsOneWidget);
    expect(_inDetail(find.text('06')), findsNothing);
  });

  testWidgets('a newer server copy takes the place of the list one', (
    tester,
  ) async {
    await bootApp(
      tester,
      repository: _catalog(
        one: (id) async =>
            sampleDish(id).copyWith(description: 'Recién salida del fogón.'),
      ),
    );
    await _openBandeja(tester);
    expect(_inDetail(find.text('Recién salida del fogón.')), findsOneWidget);
  });

  testWidgets('a dish that is gone says so and leads back', (tester) async {
    await bootApp(
      tester,
      repository: _catalog(one: (_) async => throw const AppFailure.notFound()),
    );
    await _openBandeja(tester);
    expect(
      _inDetail(find.text('Este plato ya no está en la carta.')),
      findsOneWidget,
    );

    await tester.tap(_inDetail(find.text('Volver a la carta')));
    await tester.pumpAndSettle();
    expect(find.byType(DishDetailPage), findsNothing);
  });

  testWidgets('pulling the page down far enough closes it', (tester) async {
    await bootApp(tester, repository: _catalog());
    await _openBandeja(tester);

    await tester.drag(_detailScroll, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.byType(DishDetailPage), findsNothing);
    expect(find.text('DESTACADOS'), findsOneWidget);
  });

  testWidgets('a short pull springs back', (tester) async {
    await bootApp(tester, repository: _catalog());
    await _openBandeja(tester);

    await tester.drag(_detailScroll, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.byType(DishDetailPage), findsOneWidget);
  });
}

import 'dart:async';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/design/widgets/skeleton.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/dish_fixtures.dart';

final Finder _menu = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axisDirection == .down,
);

/// A catalog whose answers are scripted call by call.
MockDishRepository _catalog(List<FutureOr<List<Dish>> Function()> answers) {
  final repository = MockDishRepository();
  var call = 0;
  when(repository.fetchAll).thenAnswer((_) async {
    final answer = answers[call < answers.length ? call : answers.length - 1];
    call++;
    return await answer();
  });
  return repository;
}

void main() {
  testWidgets('the skeleton gives way to the menu', (tester) async {
    final arrival = Completer<List<Dish>>();
    await bootApp(
      tester,
      repository: _catalog([() => arrival.future]),
      settle: false,
    );
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.text('DESTACADOS'), findsNothing);

    arrival.complete(sampleDishes);
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsNothing);
    expect(find.text('DESTACADOS'), findsOneWidget);
  });

  testWidgets('a broken photo falls back to the initials', (tester) async {
    await bootApp(tester);
    final bandeja = find.bySemanticsLabel(RegExp(r'^Bandeja Paisa\.'));
    await tester.scrollUntilVisible(bandeja, 300, scrollable: _menu.first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: bandeja, matching: find.text('BP')),
      findsOneWidget,
    );
  });

  testWidgets('an empty search names the query and clears itself', (
    tester,
  ) async {
    await bootApp(tester);
    await tester.enterText(find.byType(EditableText), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('Nada en la carta con «pizza».'), findsOneWidget);

    await tester.tap(find.text('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('DESTACADOS'), findsOneWidget);
  });

  testWidgets('offline shows its state and retries', (tester) async {
    await bootApp(
      tester,
      repository: _catalog([
        () => throw const AppFailure.offline(),
        () => sampleDishes,
      ]),
    );
    expect(find.text('Sin conexión.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('DESTACADOS'), findsOneWidget);
  });

  testWidgets('too many requests counts down before retrying', (tester) async {
    await bootApp(
      tester,
      repository: _catalog([
        () => throw const AppFailure.rateLimited(
          retryAfter: Duration(seconds: 42),
        ),
      ]),
      settle: false,
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Vas muy rápido.'), findsOneWidget);
    expect(find.text('Intenta en 0:42'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Intenta en 0:41'), findsOneWidget);
  });

  testWidgets('a server failure shows its reference', (tester) async {
    await bootApp(
      tester,
      repository: _catalog([
        () => throw const AppFailure.server(status: 500, requestId: 'ab12'),
      ]),
    );
    expect(find.text('Algo se nos quemó en la cocina.'), findsOneWidget);
    expect(find.text('Ref. ab12'), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the menu and says why', (tester) async {
    await bootApp(
      tester,
      repository: _catalog([
        () => sampleDishes,
        () => throw const AppFailure.offline(),
      ]),
    );
    await tester.fling(_menu.first, const Offset(0, 500), 2000);
    await tester.pumpAndSettle();

    expect(find.text('DESTACADOS'), findsOneWidget);
    expect(find.text('Sin conexión.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

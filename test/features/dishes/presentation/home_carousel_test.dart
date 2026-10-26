import 'package:ecoeats/features/discover/presentation/discover_page.dart';
import 'package:ecoeats/features/dishes/presentation/detail/dish_detail_page.dart';
import 'package:ecoeats/features/dishes/presentation/home/featured_carousel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/app_harness.dart';

double _dotWidth(WidgetTester tester, int index) =>
    tester.getSize(find.byKey(ValueKey('featured-dot-$index'))).width;

void main() {
  testWidgets('one card per featured dish, each read in full', (tester) async {
    await bootApp(tester);
    expect(find.text('DESTACADOS'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        r'Destacado 1 de 4. Bandeja Paisa, $ 28.000, calificación 4,9.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('featured-dot-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('featured-dot-4')), findsNothing);
  });

  testWidgets('the indicator follows the swipe', (tester) async {
    await bootApp(tester);
    expect(_dotWidth(tester, 0), greaterThan(_dotWidth(tester, 1)));

    await tester.fling(
      find.byType(FeaturedCarousel),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(_dotWidth(tester, 1), greaterThan(_dotWidth(tester, 0)));
    expect(
      find.bySemanticsLabel(RegExp('^Destacado 2 de 4. Ajiaco Santafereño')),
      findsOneWidget,
    );
  });

  testWidgets('a card opens its dish', (tester) async {
    await bootApp(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Destacado 1 de 4')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DishDetailPage),
        matching: find.text('Bandeja Paisa'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the banner opens Discover', (tester) async {
    await bootApp(tester);
    await tester.tap(find.bySemanticsLabel('Abrir el modo descubrir'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverPage), findsOneWidget);
  });

  testWidgets('searching hides the carousel and the banner', (tester) async {
    await bootApp(tester);
    await tester.enterText(find.byType(EditableText), 'camaron');
    await tester.pumpAndSettle();
    expect(find.byType(FeaturedCarousel), findsNothing);
    expect(find.bySemanticsLabel('Abrir el modo descubrir'), findsNothing);
  });
}

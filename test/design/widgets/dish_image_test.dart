import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_hero.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ecoTheme(.light),
  home: Scaffold(
    body: Center(child: SizedBox(width: 200, height: 250, child: child)),
  ),
);

void main() {
  group('DishImage', () {
    testWidgets('without a URL it shows the plate and the initials', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const DishImage(url: null, name: 'Bandeja Paisa')),
      );
      expect(find.byType(PlateIllustration), findsOneWidget);
      expect(find.text('BP'), findsOneWidget);
    });

    testWidgets('an empty URL is no URL', (tester) async {
      await tester.pumpWidget(_app(const DishImage(url: '', name: 'Ajiaco')));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('the same dish always gets the same colors', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              Expanded(
                child: DishPlaceholder(key: ValueKey('a'), name: 'Ajiaco'),
              ),
              Expanded(
                child: DishPlaceholder(key: ValueKey('b'), name: 'Ajiaco'),
              ),
            ],
          ),
        ),
      );
      final first = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(const ValueKey('a')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final second = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(const ValueKey('b')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(first.decoration, second.decoration);
    });

    testWidgets('a soft light falls on it from the upper left', (tester) async {
      await tester.pumpWidget(_app(const DishPlaceholder(name: 'Ajiaco')));
      final lights = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(DishPlaceholder),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration?)?.gradient)
          .whereType<RadialGradient>();
      expect(lights, hasLength(1));
      final center = lights.single.center as Alignment;
      expect(center.x, lessThan(0));
      expect(center.y, lessThan(0));
    });

    testWidgets('its initials are set in Fraunces italic', (tester) async {
      await tester.pumpWidget(
        _app(const DishImage(url: null, name: 'Bandeja Paisa')),
      );
      final initials = tester.widget<Text>(find.text('BP')).style!;
      expect(initials.fontFamily, EcoFonts.display);
      expect(initials.fontStyle, FontStyle.italic);
    });

    testWidgets('the photo fades in over 280 ms', (tester) async {
      await tester.pumpWidget(
        _app(
          const DishImage(
            url: 'https://images.invalid/photo.jpg',
            name: 'Ajiaco',
          ),
        ),
      );
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .fadeInDuration,
        const Duration(milliseconds: 280),
      );
    });

    testWidgets('a broken photo keeps the placeholder', (tester) async {
      await tester.pumpWidget(
        _app(
          const DishImage(
            url: 'https://images.invalid/photo.jpg',
            name: 'Bandeja Paisa',
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('BP'), findsOneWidget);
    });
  });

  group('dishInitials', () {
    test('takes the first letters of the first two words', () {
      expect(dishInitials('Bandeja Paisa'), 'BP');
      expect(dishInitials('Ajiaco'), 'A');
      expect(dishInitials('  sancocho  trifásico '), 'ST');
    });

    test('skips Spanish connectors', () {
      expect(dishInitials('Arroz con Pollo'), 'AP');
      expect(dishInitials('Posta de la Abuela'), 'PA');
    });
  });

  test('cache keys ignore the presigned parameters', () {
    const a =
        'https://s3.test/dishes/1.jpg?X-Amz-Date=20261025&X-Amz-Signature=abc&w=600';
    const b =
        'https://s3.test/dishes/1.jpg?X-Amz-Date=20261026&X-Amz-Signature=def&w=600';
    expect(stableCacheKey(a), stableCacheKey(b));
    expect(stableCacheKey(a), 'https://s3.test/dishes/1.jpg?w=600');
    expect(
      stableCacheKey('https://images.unsplash.com/photo-1?w=400'),
      'https://images.unsplash.com/photo-1?w=400',
    );
  });

  testWidgets('DishHero holds its child in a Hero with the tag', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const DishHero(tag: 'dish-1-list', child: Text('foto'))),
    );
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'dish-1-list');
    expect(
      find.descendant(of: find.byType(Hero), matching: find.text('foto')),
      findsOneWidget,
    );
  });
}

import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/theme.dart';
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

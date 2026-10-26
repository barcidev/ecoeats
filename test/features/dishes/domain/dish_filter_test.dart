import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/dish_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/dish_fixtures.dart';

List<String> _ids(List<Dish> dishes) => [for (final dish in dishes) dish.id];

void main() {
  test('the default shows every dish from A to Z', () {
    final names = const DishFilter().apply(sampleDishes).map((d) => d.name);
    expect(names, hasLength(12));
    expect(names.first, 'Ajiaco Santafereño');
    expect(names.last, 'Tamal Tolimense');
  });

  group('categories', () {
    test('featured keeps the flagged dishes', () {
      final featured = const DishFilter(category: .featured)
          .apply(sampleDishes);
      expect(_ids(featured), ['ajiaco', 'arroz', 'bandeja', 'sancocho']);
    });

    test('high in protein means 35 g or more', () {
      final strong = const DishFilter(category: .highProtein)
          .apply(sampleDishes);
      expect(strong.every((dish) => dish.proteins >= 35), isTrue);
      expect(_ids(strong), contains('pescado'));
      expect(_ids(strong), isNot(contains('arroz')));
    });

    test('light means 35 g of carbohydrates or fewer', () {
      final light = const DishFilter(category: .light).apply(sampleDishes);
      expect(light.every((dish) => dish.carbohydrates <= 35), isTrue);
      expect(_ids(light), contains('pescado'));
      expect(_ids(light), isNot(contains('lechona')));
    });
  });

  test('search and category apply together', () {
    const filter = DishFilter(query: 'camaron', category: .light);
    expect(_ids(filter.apply(sampleDishes)), ['cazuela']);
    expect(filter.isSearching, isTrue);
    expect(const DishFilter(query: '  ').isSearching, isFalse);
  });

  group('sorts', () {
    test('best rated first, ties by name', () {
      final rated = const DishFilter(sort: .topRated).apply(sampleDishes);
      expect(_ids(rated).take(3), ['bandeja', 'ajiaco', 'cazuela']);
    });

    test('price up and down', () {
      final cheap = const DishFilter(sort: .priceLow).apply(sampleDishes);
      final dear = const DishFilter(sort: .priceHigh).apply(sampleDishes);
      expect(cheap.first.id, 'changua');
      expect(dear.first.id, 'cazuela');
    });

    test('most protein first', () {
      final protein = const DishFilter(sort: .mostProtein).apply(sampleDishes);
      expect(_ids(protein).take(2), ['bandeja', 'posta']);
    });
  });
}

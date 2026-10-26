import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/presentation/dish_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, Object?> _bandejaPaisa = {
  'id': '0199c394-3880-7000-8000-000000000001',
  'name': 'Bandeja Paisa',
  'description': 'El plato más emblemático de la región antioqueña.',
  'image': 'https://images.unsplash.com/photo-1599655722738?w=600',
  'thumbails': 'https://images.unsplash.com/photo-1599655722738?w=200',
  'price': 28000.0,
  'carbohydrates': 85,
  'proteins': 55,
  'rating': 4.9,
  'ingredients': 'Frijoles rojos, arroz blanco, hogao (tomate, cebolla)',
  'flagHeader': true,
};

void main() {
  test('hero tags carry the dish and where it flies from', () {
    expect(dishHeroTag('a1', .carousel), 'dish-a1-carousel');
    expect(dishHeroTag('a1', .list), 'dish-a1-list');
    expect(dishHeroTag('a1', .discover), 'dish-a1-discover');
  });

  group('Dish.fromJson', () {
    test('reads the contract, typo included', () {
      final dish = Dish.fromJson(_bandejaPaisa);
      expect(dish.id, '0199c394-3880-7000-8000-000000000001');
      expect(dish.name, 'Bandeja Paisa');
      expect(dish.thumbnail, _bandejaPaisa['thumbails']);
      expect(dish.image, _bandejaPaisa['image']);
      expect(dish.featured, isTrue);
      expect(dish.price, 28000);
      expect(dish.carbohydrates, 85);
      expect(dish.proteins, 55);
      expect(dish.rating, 4.9);
      expect(dish.ingredients, _bandejaPaisa['ingredients']);
    });

    test('integer prices and ratings become doubles', () {
      final dish = Dish.fromJson({
        ..._bandejaPaisa,
        'price': 28000,
        'rating': 5,
      });
      expect(dish.price, isA<double>());
      expect(dish.rating, isA<double>());
      expect(dish.rating, 5.0);
    });
  });
}

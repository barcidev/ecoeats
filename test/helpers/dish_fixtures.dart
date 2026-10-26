import 'package:ecoeats/features/dishes/domain/dish.dart';

Dish _dish(
  String id,
  String name, {
  required double price,
  required int carbohydrates,
  required int proteins,
  required double rating,
  required String ingredients,
  bool featured = false,
  String image = '',
}) {
  return Dish(
    id: id,
    name: name,
    description: '$name, como en casa.',
    image: image,
    thumbnail: image,
    price: price,
    carbohydrates: carbohydrates,
    proteins: proteins,
    rating: rating,
    ingredients: ingredients,
    featured: featured,
  );
}

/// Twelve dishes shaped like the API seed: four featured, macros on both sides
/// of the filter thresholds, and one photo that is gone for good.
final List<Dish> sampleDishes = [
  _dish(
    'bandeja',
    'Bandeja Paisa',
    price: 28000,
    carbohydrates: 85,
    proteins: 55,
    rating: 4.9,
    featured: true,
    image: 'https://images.unsplash.com/photo-gone?w=600',
    ingredients:
        'Frijoles rojos, arroz blanco, chicharrón, carne molida, chorizo, '
        'huevo frito, plátano maduro, arepa, aguacate',
  ),
  _dish(
    'ajiaco',
    'Ajiaco Santafereño',
    price: 24000,
    carbohydrates: 45,
    proteins: 38,
    rating: 4.8,
    featured: true,
    ingredients:
        'Pollo, papa criolla, papa sabanera, mazorca, guascas, '
        'crema de leche, alcaparras',
  ),
  _dish(
    'sancocho',
    'Sancocho Trifásico',
    price: 26000,
    carbohydrates: 50,
    proteins: 42,
    rating: 4.7,
    featured: true,
    ingredients: 'Res, cerdo, pollo, yuca, plátano verde, mazorca, cilantro',
  ),
  _dish(
    'arroz',
    'Arroz con Camarones',
    price: 32000,
    carbohydrates: 60,
    proteins: 30,
    rating: 4.6,
    featured: true,
    ingredients: 'Arroz, camarones, coco, hogao (tomate, cebolla), cilantro',
  ),
  _dish(
    'posta',
    'Posta Negra Cartagenera',
    price: 34000,
    carbohydrates: 20,
    proteins: 48,
    rating: 4.5,
    ingredients: 'Posta de res, panela, cebolla, ajo, pimienta',
  ),
  _dish(
    'mote',
    'Mote de Queso',
    price: 18000,
    carbohydrates: 30,
    proteins: 22,
    rating: 4.4,
    ingredients: 'Ñame, queso costeño, cebolla, ajo, limón',
  ),
  _dish(
    'lechona',
    'Lechona Tolimense',
    price: 25000,
    carbohydrates: 40,
    proteins: 45,
    rating: 4.6,
    ingredients: 'Cerdo, arroz, arveja, cebolla, comino',
  ),
  _dish(
    'cazuela',
    'Cazuela de Mariscos',
    price: 38000,
    carbohydrates: 18,
    proteins: 40,
    rating: 4.8,
    ingredients: 'Camarones, calamar, pescado, leche de coco, ají dulce',
  ),
  _dish(
    'tamal',
    'Tamal Tolimense',
    price: 15000,
    carbohydrates: 55,
    proteins: 25,
    rating: 4.3,
    ingredients: 'Masa de maíz, cerdo, pollo, huevo, zanahoria, arveja',
  ),
  _dish(
    'ensalada',
    'Ensalada de Aguacate',
    price: 16000,
    carbohydrates: 12,
    proteins: 6,
    rating: 4.2,
    ingredients: 'Aguacate, tomate, cebolla morada, cilantro, limón',
  ),
  _dish(
    'pescado',
    'Pescado Frito con Patacón',
    price: 30000,
    carbohydrates: 35,
    proteins: 36,
    rating: 4.5,
    ingredients: 'Mojarra, patacón, arroz con coco, ensalada',
  ),
  _dish(
    'changua',
    'Changua',
    price: 12000,
    carbohydrates: 15,
    proteins: 18,
    rating: 4.1,
    ingredients: 'Leche, huevo, cebolla larga, cilantro, calado',
  ),
];

Dish sampleDish(String id) => sampleDishes.firstWhere((dish) => dish.id == id);

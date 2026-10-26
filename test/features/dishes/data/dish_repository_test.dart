import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/features/dishes/data/dish_api.dart';
import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http_adapter.dart';

Map<String, Object?> _json(String id, String name) => {
  'id': id,
  'name': name,
  'description': 'Descripción',
  'image': 'https://images.unsplash.com/photo-1?w=600',
  'thumbails': 'https://images.unsplash.com/photo-1?w=200',
  'price': 24000,
  'carbohydrates': 40,
  'proteins': 30,
  'rating': 4.5,
  'ingredients': 'Arroz, pollo',
  'flagHeader': false,
};

void main() {
  late FakeHttpAdapter adapter;
  late DishRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    repository = DishRepository(DishApi(dio));
  });

  test('lists the dishes of the envelope', () async {
    adapter.ok('GET', '/api/dish', [
      _json('a', 'Ajiaco'),
      _json('b', 'Sancocho'),
    ]);
    final dishes = await repository.fetchAll();
    expect(dishes.map((dish) => dish.name), ['Ajiaco', 'Sancocho']);
  });

  test('fetches one dish by id', () async {
    adapter.ok('GET', '/api/dish/a', _json('a', 'Ajiaco'));
    final dish = await repository.fetchOne('a');
    expect(dish.name, 'Ajiaco');
  });

  test('a dish that is gone is not found', () async {
    adapter.reply(
      'GET',
      '/api/dish/x',
      status: 404,
      body: {'success': false, 'message': 'Plato no encontrado'},
    );
    await expectLater(
      repository.fetchOne('x'),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}

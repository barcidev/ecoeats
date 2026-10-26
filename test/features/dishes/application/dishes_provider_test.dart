import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDishRepository extends Mock implements DishRepository;

Dish _dish(String id) => Dish(
  id: id,
  name: 'Plato $id',
  description: '',
  image: '',
  thumbnail: '',
  price: 20000,
  carbohydrates: 30,
  proteins: 20,
  rating: 4,
  ingredients: '',
  featured: false,
);

void main() {
  late _MockDishRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockDishRepository();
    container = ProviderContainer.test(
      overrides: [dishRepositoryProvider.overrideWithValue(repository)],
    );
  });

  test('holds the repository list', () async {
    when(repository.fetchAll).thenAnswer((_) async => [_dish('a')]);
    final dishes = await container.read(dishesProvider.future);
    expect(dishes, [_dish('a')]);
  });

  test('refresh fetches again', () async {
    when(repository.fetchAll).thenAnswer((_) async => [_dish('a')]);
    await container.read(dishesProvider.future);
    when(repository.fetchAll).thenAnswer((_) async => [_dish('a'), _dish('b')]);

    await container.read(dishesProvider.notifier).refresh();

    expect(container.read(dishesProvider).value, hasLength(2));
    verify(repository.fetchAll).called(2);
  });

  test('a failed refresh keeps the list it had', () async {
    when(repository.fetchAll).thenAnswer((_) async => [_dish('a')]);
    await container.read(dishesProvider.future);
    when(repository.fetchAll).thenThrow(const AppFailure.offline());

    await container.read(dishesProvider.notifier).refresh();

    final state = container.read(dishesProvider);
    expect(state.error, const AppFailure.offline());
    expect(state.value, [_dish('a')]);
  });
}

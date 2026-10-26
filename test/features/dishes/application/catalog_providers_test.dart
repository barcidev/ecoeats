import 'dart:async';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/application/dish_detail_provider.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/dish_fixtures.dart';

class _MockDishRepository extends Mock implements DishRepository;

void main() {
  late _MockDishRepository repository;
  late ProviderContainer container;

  setUp(() async {
    repository = _MockDishRepository();
    when(repository.fetchAll).thenAnswer((_) async => sampleDishes);
    // Home keeps the list alive while the catalog is on screen.
    container = ProviderContainer.test(
      overrides: [dishRepositoryProvider.overrideWithValue(repository)],
    )..listen(dishesProvider, (_, _) {});
    await container.read(dishesProvider.future);
  });

  group('visibleDishes', () {
    test('follows the filter without leaving its data state', () {
      container.listen(visibleDishesProvider, (_, _) {});
      expect(container.read(visibleDishesProvider).value, hasLength(12));

      container.read(catalogFilterProvider.notifier)
        ..select(.featured)
        ..sortBy(.priceHigh);
      final featured = container.read(visibleDishesProvider);
      expect(featured.isLoading, isFalse);
      expect(featured.value!.map((dish) => dish.id), [
        'arroz',
        'bandeja',
        'sancocho',
        'ajiaco',
      ]);

      container.read(catalogFilterProvider.notifier).search('guascas');
      expect(container.read(visibleDishesProvider).value!.single.id, 'ajiaco');

      container.read(catalogFilterProvider.notifier).clearSearch();
      expect(container.read(catalogFilterProvider).query, isEmpty);
    });
  });

  test('a failed refresh keeps the visible and featured dishes', () async {
    container
      ..listen(visibleDishesProvider, (_, _) {})
      ..listen(featuredDishesProvider, (_, _) {});
    when(repository.fetchAll).thenThrow(const AppFailure.offline());

    await container.read(dishesProvider.notifier).refresh();

    expect(container.read(dishesProvider).hasError, isTrue);
    expect(container.read(visibleDishesProvider).value, hasLength(12));
    expect(container.read(featuredDishesProvider).value, hasLength(4));
  });

  test('featuredDishes ignores the filter', () {
    container.read(catalogFilterProvider.notifier).select(.light);
    final featured = container.read(featuredDishesProvider).value!;
    expect(featured, hasLength(4));
    expect(featured.every((dish) => dish.featured), isTrue);
  });

  group('dishDetail', () {
    test('shows the listed dish at once, then the server copy', () async {
      final server = Completer<Dish>();
      when(() => repository.fetchOne('ajiaco'))
          .thenAnswer((_) => server.future);
      final states = <AsyncValue<Dish>>[];
      container.listen(
        dishDetailProvider('ajiaco'),
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(
        container.read(dishDetailProvider('ajiaco')).value,
        sampleDish('ajiaco'),
      );

      final fresh = sampleDish('ajiaco').copyWith(description: 'Recién hecho.');
      server.complete(fresh);
      await pumpEventQueue();
      expect(container.read(dishDetailProvider('ajiaco')).value, fresh);
    });

    test('a dish that is gone ends in notFound', () async {
      when(() => repository.fetchOne('ajiaco'))
          .thenThrow(const AppFailure.notFound());
      container.listen(dishDetailProvider('ajiaco'), (_, _) {});
      await pumpEventQueue();
      expect(
        container.read(dishDetailProvider('ajiaco')).error,
        isA<NotFoundFailure>(),
      );
    });

    test('a dish the list does not know waits for the server', () async {
      final server = Completer<Dish>();
      when(() => repository.fetchOne('nuevo')).thenAnswer((_) => server.future);
      container.listen(dishDetailProvider('nuevo'), (_, _) {});
      await pumpEventQueue();
      expect(container.read(dishDetailProvider('nuevo')).isLoading, isTrue);

      server.complete(sampleDish('mote').copyWith(id: 'nuevo'));
      await pumpEventQueue();
      expect(container.read(dishDetailProvider('nuevo')).value?.id, 'nuevo');
    });
  });
}

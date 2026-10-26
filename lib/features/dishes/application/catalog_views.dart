import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_views.g.dart';

// Both views are synchronous over the list's AsyncValue: a new filter maps
// the data at once instead of passing through a loading state.

/// «La carta» as the user filtered, searched and sorted it.
@riverpod
AsyncValue<List<Dish>> visibleDishes(Ref ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref.watch(dishesProvider).whenData(filter.apply);
}

/// The carousel: featured dishes, whatever the filter says.
@riverpod
AsyncValue<List<Dish>> featuredDishes(Ref ref) {
  return ref
      .watch(dishesProvider)
      .whenData(
        (dishes) => [
          for (final dish in dishes)
            if (dish.featured) dish,
        ],
      );
}

import 'package:ecoeats/features/dishes/domain/dish_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_filter.g.dart';

/// What the user asked of the catalog: Home edits it, and both «La carta» and
/// Discover read the dishes through it.
@riverpod
class CatalogFilter extends _$CatalogFilter {
  @override
  DishFilter build() => const DishFilter();

  void search(String query) => state = state.copyWith(query: query);

  void clearSearch() => state = state.copyWith(query: '');

  void select(DishCategory category) =>
      state = state.copyWith(category: category);

  void sortBy(DishSort sort) => state = state.copyWith(sort: sort);
}

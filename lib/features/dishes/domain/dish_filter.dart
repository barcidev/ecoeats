import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/features/dishes/domain/text_search.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish_filter.freezed.dart';

/// The pills above «La carta».
enum DishCategory {
  all,
  featured,
  highProtein,
  light;

  static const proteinGrams = 35;
  static const carbohydrateGrams = 35;

  bool includes(Dish dish) => switch (this) {
    all => true,
    featured => dish.featured,
    highProtein => dish.proteins >= proteinGrams,
    light => dish.carbohydrates <= carbohydrateGrams,
  };
}

enum DishSort { alphabetical, topRated, priceLow, priceHigh, mostProtein }

@freezed
abstract class DishFilter with _$DishFilter {
  const factory({
    @Default('') String query,
    @Default(DishCategory.all) DishCategory category,
    @Default(DishSort.alphabetical) DishSort sort,
  }) = _DishFilter;

  const new _();

  bool get isSearching => query.trim().isNotEmpty;

  /// The dishes that pass the category and the search, in the chosen order;
  /// equal values fall back to the name so the order never jumps.
  List<Dish> apply(Iterable<Dish> dishes) {
    final kept = [
      for (final dish in dishes)
        if (category.includes(dish) &&
            matchesSearch(query, [dish.name, dish.ingredients]))
          dish,
    ];
    int byName(Dish a, Dish b) =>
        foldForSearch(a.name).compareTo(foldForSearch(b.name));
    return kept..sort((a, b) {
      final order = switch (sort) {
        .alphabetical => 0,
        .topRated => b.rating.compareTo(a.rating),
        .priceLow => a.price.compareTo(b.price),
        .priceHigh => b.price.compareTo(a.price),
        .mostProtein => b.proteins.compareTo(a.proteins),
      };
      return order != 0 ? order : byName(a, b);
    });
  }
}

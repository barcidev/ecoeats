import 'package:ecoeats/features/dishes/data/dish_api.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_repository.g.dart';

@Riverpod(keepAlive: true)
DishRepository dishRepository(Ref ref) =>
    DishRepository(ref.watch(dishApiProvider));

/// The catalog's source. Image URLs expire, so nothing here is cached beyond
/// what the providers hold in memory.
class DishRepository {
  const new(this._api);

  final DishApi _api;

  Future<List<Dish>> fetchAll() => _api.list();

  Future<Dish> fetchOne(String id) => _api.find(id);
}

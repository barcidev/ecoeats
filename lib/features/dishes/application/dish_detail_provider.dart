import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_detail_provider.g.dart';

/// One dish: the copy the list already holds right away, so the detail never
/// opens empty, then the server's. A 404 ends in `notFound` even after the
/// list's copy, because the dish is no longer on the menu.
@riverpod
Stream<Dish> dishDetail(Ref ref, String id) async* {
  final repository = ref.watch(dishRepositoryProvider);
  // Read, not watched: a list refresh must not restart an open detail.
  final listed = ref
      .read(dishesProvider)
      .value
      ?.where((dish) => dish.id == id)
      .firstOrNull;
  if (listed != null) yield listed;
  yield await repository.fetchOne(id);
}

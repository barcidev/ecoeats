import 'package:ecoeats/features/dishes/data/dish_repository.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dishes_provider.g.dart';

@riverpod
class Dishes extends _$Dishes {
  @override
  Future<List<Dish>> build() => ref.watch(dishRepositoryProvider).fetchAll();

  /// Fetches the list again for pull-to-refresh. Riverpod keeps the previous
  /// list in the loading and error states, so the screen never goes blank,
  /// and the returned future completes either way to release the spinner.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(dishRepositoryProvider).fetchAll);
  }
}

import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/api_envelope.dart';
import 'package:ecoeats/core/network/dio_provider.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dish_api.g.dart';

@Riverpod(keepAlive: true)
DishApi dishApi(Ref ref) => DishApi(ref.watch(dioProvider));

class DishApi {
  const new(this._dio);

  final Dio _dio;

  Future<List<Dish>> list() {
    return request(
      () => _dio.get<Object?>('/api/dish'),
      (data) => [
        for (final item in data! as List)
          Dish.fromJson(item as Map<String, Object?>),
      ],
    );
  }

  Future<Dish> find(String id) {
    return request(
      () => _dio.get<Object?>('/api/dish/${Uri.encodeComponent(id)}'),
      (data) => Dish.fromJson(data! as Map<String, Object?>),
    );
  }
}

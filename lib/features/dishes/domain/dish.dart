import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish.freezed.dart';
part 'dish.g.dart';

/// A dish of the catalog. Its name, description and ingredients arrive in
/// Spanish and are shown as they are in every language.
@freezed
abstract class Dish with _$Dish {
  const factory({
    required String id,
    required String name,
    required String description,

    /// Temporary URL (it may be presigned); never persisted.
    required String image,

    /// The contract spells it `thumbails`, on purpose.
    @JsonKey(name: 'thumbails') required String thumbnail,
    required double price,
    required int carbohydrates,
    required int proteins,
    required double rating,

    /// Comma separated, with commas inside parentheses too.
    required String ingredients,
    @JsonKey(name: 'flagHeader') required bool featured,
  }) = _Dish;

  factory fromJson(Map<String, Object?> json) => _$DishFromJson(json);
}

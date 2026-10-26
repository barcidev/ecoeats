import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

// The API names register fields in Spanish and login fields in English; the
// DTOs keep English names in Dart and map the keys.

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory({
    @JsonKey(name: 'numero_documento') required String documentNumber,
    @JsonKey(name: 'nombres') required String firstNames,
    @JsonKey(name: 'apellidos') required String lastNames,
    @JsonKey(name: 'correo') required String email,
    required String password,
  }) = _RegisterRequest;

  factory fromJson(Map<String, Object?> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
abstract class RegisteredUser with _$RegisteredUser {
  const factory({
    required String id,
    @JsonKey(name: 'numero_documento') required String documentNumber,
    @JsonKey(name: 'nombres') required String firstNames,
    @JsonKey(name: 'apellidos') required String lastNames,
    @JsonKey(name: 'correo') required String email,
  }) = _RegisteredUser;

  factory fromJson(Map<String, Object?> json) => _$RegisteredUserFromJson(json);
}

/// `tokenFirebaseAuth` is a leftover of the contract and stays unread.
@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory({
    required String id,
    required String email,
    required String token,
  }) = _LoginResponse;

  factory fromJson(Map<String, Object?> json) => _$LoginResponseFromJson(json);
}

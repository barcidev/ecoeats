import 'package:dio/dio.dart';
import 'package:ecoeats/core/network/api_envelope.dart';
import 'package:ecoeats/core/network/dio_provider.dart';
import 'package:ecoeats/features/auth/data/auth_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(dioProvider));

/// The `/api/securities` endpoints, with the paths and JSON shapes of the
/// production contract.
class AuthApi {
  const new(this._dio);

  static const _base = '/api/securities';

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) {
    return _post('login', {
      'email': email,
      'password': password,
    }, (data) => LoginResponse.fromJson(_map(data)));
  }

  Future<RegisteredUser> register(RegisterRequest body) {
    return _post(
      'register',
      body.toJson(),
      (data) => RegisteredUser.fromJson(_map(_map(data)['user'])),
    );
  }

  Future<void> forgotPassword(String email) =>
      _post('forgot-password', {'email': email}, (_) {});

  Future<bool> verifyOtp({required String email, required String otp}) {
    return _post('verify-otp', {
      'email': email,
      'otp': otp,
    }, (data) => _map(data)['valid']! as bool);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _post('reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    }, (_) {});
  }

  Future<T> _post<T>(
    String path,
    Map<String, Object?> body,
    T Function(Object? data) parse,
  ) {
    return request(() => _dio.post<Object?>('$_base/$path', data: body), parse);
  }

  static Map<String, Object?> _map(Object? data) =>
      data! as Map<String, Object?>;
}

import 'package:ecoeats/features/auth/data/auth_api.dart';
import 'package:ecoeats/features/auth/data/auth_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(authApiProvider));

/// The server trims and lowercases emails too; doing it first keeps the email
/// the app stores equal to the one the server answers with.
String normalizeEmail(String email) => email.trim().toLowerCase();

/// What the app needs from the security endpoints. Passwords travel as typed:
/// a leading space may be part of one.
class AuthRepository {
  const new(this._api);

  final AuthApi _api;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) => _api.login(email: normalizeEmail(email), password: password);

  /// Returns the new user without a session: the API issues no token on
  /// register, so the caller logs in afterwards.
  Future<RegisteredUser> register({
    required String documentNumber,
    required String firstNames,
    required String lastNames,
    required String email,
    required String password,
  }) {
    return _api.register(
      RegisterRequest(
        documentNumber: documentNumber.trim(),
        firstNames: firstNames.trim(),
        lastNames: lastNames.trim(),
        email: normalizeEmail(email),
        password: password,
      ),
    );
  }

  Future<void> forgotPassword(String email) =>
      _api.forgotPassword(normalizeEmail(email));

  Future<bool> verifyOtp({required String email, required String otp}) =>
      _api.verifyOtp(email: normalizeEmail(email), otp: otp.trim());

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _api.resetPassword(
      email: normalizeEmail(email),
      otp: otp.trim(),
      newPassword: newPassword,
    );
  }
}

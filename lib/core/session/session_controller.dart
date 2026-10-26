import 'dart:async';

import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/core/session/jwt.dart';
import 'package:ecoeats/core/session/session.dart';
import 'package:ecoeats/core/session/token_store.dart';
import 'package:ecoeats/features/auth/data/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

/// Counts the sessions the server ended by rejecting their token; the UI
/// listens to it to say «your session expired».
@Riverpod(keepAlive: true)
class SessionExpired extends _$SessionExpired {
  @override
  int build() => 0;

  void raise() => state++;
}

/// The signed-in user, or `null`. It restores the stored token at start, so
/// the native splash stays up until this first build completes.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  TokenStore get _store => ref.read(tokenStoreProvider);

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  DateTime get _now => ref.read(clockProvider)();

  @override
  Future<Session?> build() async {
    final token = await _store.readToken();
    if (token == null) return null;
    final session = await _sessionFrom(token);
    if (session == null || session.isExpiredAt(_now)) {
      await _store.deleteToken();
      return null;
    }
    return session;
  }

  /// Throws the [AppFailure] of a rejected login and leaves no session.
  Future<void> login({required String email, required String password}) async {
    final response = await _auth.login(email: email, password: password);
    final session = await _sessionFrom(response.token, email: response.email);
    if (session == null) {
      throw const AppFailure.unknown(cause: 'Unreadable token');
    }
    await _store.writeToken(response.token);
    state = AsyncData(session);
  }

  /// The API issues no token on register, so this logs in right after with
  /// the same credentials.
  Future<void> register({
    required String documentNumber,
    required String firstNames,
    required String lastNames,
    required String email,
    required String password,
  }) async {
    final user = await _auth.register(
      documentNumber: documentNumber,
      firstNames: firstNames,
      lastNames: lastNames,
      email: email,
      password: password,
    );
    await _store.writeFirstNames(user.email, user.firstNames);
    await login(email: user.email, password: password);
  }

  Future<void> logout() async {
    await _store.deleteToken();
    state = const AsyncData(null);
  }

  /// Called by the interceptor on a 401. Several requests may fail together,
  /// so the session closes synchronously and the signal is raised only once.
  void onUnauthorized() {
    if (state.value == null) return;
    state = const AsyncData(null);
    ref.read(sessionExpiredProvider.notifier).raise();
    unawaited(_store.deleteToken());
  }

  Future<Session?> _sessionFrom(String token, {String? email}) async {
    final claims = decodeJwt(token);
    if (claims == null) return null;
    final owner = email ?? claims.email;
    return Session(
      token: token,
      userId: claims.subject,
      email: owner,
      role: claims.role.isEmpty ? null : claims.role,
      expiresAt: claims.expiresAt,
      firstNames: await _store.readFirstNames(owner),
    );
  }
}

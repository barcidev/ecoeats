import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_store.g.dart';

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => const SecureTokenStore();

abstract interface class TokenStore {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> deleteToken();

  Future<String?> readFirstNames(String email);

  Future<void> writeFirstNames(String email, String firstNames);
}

/// Keychain on iOS, encrypted shared preferences on Android.
class SecureTokenStore implements TokenStore {
  const new([this._storage = const FlutterSecureStorage()]);

  static const _tokenKey = 'session.token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  @override
  Future<String?> readFirstNames(String email) =>
      _storage.read(key: _firstNamesKey(email));

  @override
  Future<void> writeFirstNames(String email, String firstNames) =>
      _storage.write(key: _firstNamesKey(email), value: firstNames);

  String _firstNamesKey(String email) => 'session.firstNames.$email';
}

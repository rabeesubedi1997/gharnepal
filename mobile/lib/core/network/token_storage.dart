import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps the OS keystore/keychain for the Sanctum personal access token
/// issued by POST /auth/register and /auth/login (see backend's
/// AuthController — Phase 0 added `token` to those responses specifically
/// for native clients like this one).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

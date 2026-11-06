import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'protheus_access_token';
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readToken() => _secureStorage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _secureStorage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _secureStorage.delete(key: _tokenKey);
}

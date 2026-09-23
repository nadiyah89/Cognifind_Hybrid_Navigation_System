import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage instance
final _storage = const FlutterSecureStorage();

/// Key used to store JWT token
const _tokenKey = "auth_token";

class TokenStorage {

  /// Save JWT token securely
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get stored token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete token (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
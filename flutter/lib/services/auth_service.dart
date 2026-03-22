import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _tokenKey = 'jwt_token';
  static const _onboardedKey = 'onboarded';
  static const _migratedKey = 'token_migrated';

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// SharedPreferences → SecureStorage 마이그레이션 (1회)
  Future<void> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final oldToken = prefs.getString(_tokenKey);
    if (oldToken != null && oldToken.isNotEmpty) {
      await _secure.write(key: _tokenKey, value: oldToken);
      await prefs.remove(_tokenKey);
    }
    await prefs.setBool(_migratedKey, true);
  }

  Future<String?> getToken() async {
    await _migrateIfNeeded();
    return await _secure.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _secure.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _secure.delete(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }
}

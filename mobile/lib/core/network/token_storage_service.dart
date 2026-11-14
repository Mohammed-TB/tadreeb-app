import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  TokenStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'tadreeb_auth_token';
  // يحفظ البيانات بشكل آمن على الجهاز.
  final FlutterSecureStorage _storage;
  //قراءة التوكن المحفوظ
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  // حفظ التوكن بعد تسجيل الدخول
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  // حذف التوكن عند تسجيل الخروج
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorageService? tokenStorage,
    GoogleSignIn? googleSignIn,
    String? googleServerClientId,
  }) : this._(
         apiClient,
         tokenStorage ?? TokenStorageService(),
         googleSignIn ?? GoogleSignIn.instance,
         googleServerClientId ??
             const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
       );

  AuthService._(
    ApiClient? apiClient,
    TokenStorageService tokenStorage,
    this._googleSignIn,
    this._googleServerClientId,
  ) : _tokenStorage = tokenStorage,
      _apiClient = apiClient ?? ApiClient(tokenStorage: tokenStorage);

  static const _registerPath = '/api/auth/register';
  static const _loginPath = '/api/auth/login';
  static const _googlePath = '/api/auth/google';
  static const _mePath = '/api/auth/me';

  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;
  final GoogleSignIn _googleSignIn;
  final String _googleServerClientId;
  bool _googleInitialized = false;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      _registerPath,
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    return _saveAuthenticatedResponse(response);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      _loginPath,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return _saveAuthenticatedResponse(response);
  }

  Future<UserModel> loginWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      throw const ApiException(
        'إعداد Google غير مكتمل. أضف Google Web Client ID عبر '
        '--dart-define=GOOGLE_SERVER_CLIENT_ID',
      );
    }

    if (!_googleInitialized) {
      try {
        await _googleSignIn.initialize(serverClientId: _googleServerClientId);
        _googleInitialized = true;
      } on GoogleSignInException {
        throw const ApiException(
          'تعذر تهيئة Google Sign-In. تحقق من إعدادات OAuth الخاصة بالتطبيق',
        );
      }
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const ApiException(
        'تسجيل الدخول عبر Google غير مدعوم على هذا الجهاز',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const ApiException('تم إلغاء تسجيل الدخول عبر Google');
      }
      throw const ApiException(
        'تعذر تسجيل الدخول عبر Google. تحقق من إعدادات OAuth وحاول مجددًا',
      );
    }
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const ApiException(
        'تعذر الحصول على رمز Google. تحقق من إعدادات OAuth وحاول مجددًا',
      );
    }

    final response = await _apiClient.post(
      _googlePath,
      body: {'idToken': idToken},
    );
    return _saveAuthenticatedResponse(response);
  }

  Future<UserModel?> restoreSession() async {
    final String? token;
    try {
      token = await _tokenStorage.readToken();
    } catch (_) {
      throw const ApiException('تعذر قراءة الجلسة الآمنة من الجهاز');
    }
    if (token == null || token.isEmpty) return null;

    final response = await _apiClient.get(_mePath, authenticated: true);
    final userJson = response['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiException('استجابة المستخدم الحالي غير صالحة');
    }
    return UserModel.fromJson(userJson);
  }

  Future<void> logout() async {
    try {
      await _tokenStorage.deleteToken();
    } catch (_) {
      throw const ApiException('تعذر حذف رمز الجلسة من التخزين الآمن');
    }
  }

  Future<UserModel> _saveAuthenticatedResponse(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('استجابة المصادقة غير صالحة');
    }
    final userJson = data['user'];
    final token = data['token'];
    if (userJson is! Map<String, dynamic> ||
        token is! String ||
        token.isEmpty) {
      throw const ApiException('استجابة المصادقة لا تحتوي بيانات جلسة صالحة');
    }

    final user = UserModel.fromJson(userJson);
    try {
      await _tokenStorage.saveToken(token);
    } catch (_) {
      throw const ApiException('تعذر حفظ جلسة الدخول بصورة آمنة');
    }
    return user;
  }
}

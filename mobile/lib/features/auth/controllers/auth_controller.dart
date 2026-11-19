import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  UserModel? _currentUser;
  bool _isGuest = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _runAuthentication(
    () => _authService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    ),
  );

  Future<bool> login({required String email, required String password}) =>
      _runAuthentication(
        () => _authService.login(email: email, password: password),
      );

  Future<bool> loginWithGoogle() =>
      _runAuthentication(_authService.loginWithGoogle);

  void continueAsGuest() {
    _currentUser = null;
    _isGuest = true;
    _isInitializing = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _isInitializing = true;
    _isGuest = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.restoreSession();
    } on ApiException catch (error) {
      _currentUser = null;
      _errorMessage = error.message;
      if (error.statusCode == 401 || error.statusCode == 403) {
        try {
          await _authService.logout();
        } on ApiException catch (storageError) {
          _errorMessage = '${error.message}. ${storageError.message}';
        }
      }
    } catch (error) {
      _currentUser = null;
      _errorMessage = 'تعذر التحقق من الجلسة: $error';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final wasGuest = _isGuest;
    _currentUser = null;
    _isGuest = false;
    _errorMessage = null;
    notifyListeners();

    if (wasGuest) return;

    try {
      await _authService.logout();
    } catch (error) {
      _errorMessage = 'تعذر حذف بيانات الجلسة من الجهاز: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> _runAuthentication(
    Future<UserModel> Function() authenticate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await authenticate();
      _isGuest = false;
      return true;
    } catch (error) {
      _errorMessage = error is ApiException
          ? error.message
          : 'تعذر إكمال تسجيل الدخول. حاول مرة أخرى';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

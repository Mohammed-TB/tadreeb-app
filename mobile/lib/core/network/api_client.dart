import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_storage_service.dart';

class ApiClient {
  ApiClient({
    required TokenStorageService tokenStorage,
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl =
           (baseUrl ??
                   const String.fromEnvironment(
                     'API_BASE_URL',
                     defaultValue: 'http://10.0.2.2:5000',
                   ))
               .replaceFirst(RegExp(r'/+$'), '');

  final TokenStorageService _tokenStorage;
  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) =>
      _send('GET', path, authenticated: authenticated);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('انتهت الجلسة، يرجى تسجيل الدخول مجددًا');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw const ApiException(
        'انتهت مهلة الاتصال بالخادم. تحقق من اتصالك وحاول مجددًا',
      );
    } on SocketException {
      throw const ApiException(
        'تعذر الاتصال بالإنترنت أو بالخادم. تحقق من اتصالك وحاول مجددًا',
      );
    } on http.ClientException {
      throw const ApiException(
        'تعذر الاتصال بالخادم. تحقق من عنوان الخدمة واتصالك بالإنترنت',
      );
    } on FormatException {
      throw const ApiException('استجابة الخادم غير صالحة');
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('استجابة الخادم غير صالحة');
    }

    final payload = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final serverMessage = payload?['message'];
      throw ApiException(
        _errorMessage(response.statusCode, serverMessage),
        statusCode: response.statusCode,
      );
    }

    if (payload == null) {
      throw const ApiException('استجابة الخادم غير صالحة');
    }
    if (payload['success'] == false) {
      throw ApiException(
        _errorMessage(response.statusCode, payload['message']),
        statusCode: response.statusCode,
      );
    }
    return payload;
  }

  String _errorMessage(int statusCode, Object? serverMessage) {
    final message = serverMessage is String ? serverMessage : '';
    if (statusCode == 401) {
      if (message == 'Invalid email or password') {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      return 'انتهت الجلسة أو بيانات الدخول غير صحيحة';
    }
    if (statusCode == 403) {
      if (message.contains('not active')) {
        return 'الحساب غير نشط. يرجى التواصل مع إدارة المنصة';
      }
      if (message.contains('Google login is only available')) {
        return 'تسجيل الدخول عبر Google متاح لحسابات الطلاب فقط';
      }
      return 'ليس لديك صلاحية تنفيذ هذا الإجراء';
    }
    if (statusCode == 409 || message == 'Email is already registered') {
      return 'البريد الإلكتروني مسجل مسبقًا';
    }
    if (statusCode == 400) {
      if (message == 'Email is already registered') {
        return 'البريد الإلكتروني مسجل مسبقًا';
      }
      if (message == 'Invalid email or password') {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      if (message == 'Google ID Token is required' ||
          message == 'Invalid Google account') {
        return 'تعذر التحقق من حساب Google. حاول تسجيل الدخول مرة أخرى';
      }
      if (message == 'This email is linked to another Google account') {
        return 'هذا البريد مرتبط بحساب Google آخر';
      }
      return 'البيانات المدخلة غير صحيحة. تحقق منها وحاول مجددًا';
    }
    if (statusCode >= 500) {
      return 'حدث خطأ في الخادم. حاول مرة أخرى لاحقًا';
    }
    return 'تعذر إكمال الطلب. حاول مرة أخرى';
  }
}

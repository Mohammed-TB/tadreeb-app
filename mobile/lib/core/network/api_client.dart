
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage_service.dart';

class ApiClient {
  ApiClient({
    required TokenStorageService tokenStorage,
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl)
           .replaceFirst(RegExp(r'/+$'), '');

  final TokenStorageService _tokenStorage;
  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

Future<Map<String, dynamic>> get(
  String path, {
  Map<String, dynamic>? queryParameters,
  bool authenticated = false,
}) {
  return _send(
    'GET',
    path,
    queryParameters: queryParameters,
    authenticated: authenticated,
  );
}

  // POST request
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required bool authenticated,
    List<int>? fileBytes,
    String? fileField,
    String? fileName,
    String? contentType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$path'),
    )..headers['Accept'] = 'application/json';

    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('انتهت الجلسة، يرجى تسجيل الدخول مجددًا');
      }
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    if (fileBytes != null) {
      if (fileField == null || fileName == null || contentType == null) {
        throw ArgumentError(
          'File field, name, and content type are required when uploading a file',
        );
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
    }

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw const ApiException('انتهت مهلة الاتصال بالخادم. حاول مجددًا');
    } on SocketException {
      throw const ApiException('تعذر الاتصال بالخادم. تحقق من تشغيل Backend');
    } on http.ClientException {
      throw const ApiException('تعذر الاتصال بالخادم. تحقق من عنوان الخدمة');
    } on FormatException {
      throw const ApiException('استجابة الخادم غير صالحة');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      'PUT',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      'PATCH',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = false,
  }) {
    return _send('DELETE', path, authenticated: authenticated);
  }
// Central request handler
Future<Map<String, dynamic>> _send(
  String method,
  String path, {
  Map<String, dynamic>? body,
  Map<String, dynamic>? queryParameters,
  required bool authenticated,
}) async {
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Attach Tadreeb JWT when authentication is required.
  if (authenticated) {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'انتهت الجلسة، يرجى تسجيل الدخول مجددًا',
      );
    }

    headers['Authorization'] = 'Bearer $token';
  }

  final baseUri = Uri.parse('$_baseUrl$path');

  final uri = baseUri.replace(
    queryParameters: queryParameters?.map(
      (key, value) => MapEntry(key, value.toString()),
    ),
  );

  final request = http.Request(method, uri)
    ..headers.addAll(headers);

  if (body != null) {
    request.body = jsonEncode(body);
  }

  try {
    final streamed = await _client.send(request).timeout(timeout);

    final response = await http.Response.fromStream(
      streamed,
    ).timeout(timeout);

    return _parseResponse(response);
  } on TimeoutException {
    throw const ApiException(
      'انتهت مهلة الاتصال بالخادم. حاول مجددًا',
    );
  } on SocketException {
    throw const ApiException(
      'تعذر الاتصال بالخادم. تحقق من تشغيل Backend',
    );
  } on http.ClientException {
    throw const ApiException(
      'تعذر الاتصال بالخادم. تحقق من عنوان الخدمة',
    );
  } on FormatException {
    throw const ApiException(
      'استجابة الخادم غير صالحة',
    );
  }
}

  // Parse server response and handle HTTP errors.
  Map<String, dynamic> _parseResponse(http.Response response) {
    final Object? decoded;

    try {
      decoded = response.body.isEmpty
          ? null
          : jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('استجابة الخادم غير صالحة');
    }

    final payload = decoded is Map<String, dynamic>
        ? decoded
        : null;

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(
          response.statusCode,
          payload?['message'],
        ),
        statusCode: response.statusCode,
      );
    }

    if (payload == null) {
      throw const ApiException('استجابة الخادم غير صالحة');
    }

    if (payload['success'] == false) {
      throw ApiException(
        _errorMessage(
          response.statusCode,
          payload['message'],
        ),
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  // Convert backend errors into Arabic messages.
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
        return 'تسجيل الدخول عبر Google متاح للطلاب فقط';
      }

      return 'ليس لديك صلاحية تنفيذ هذا الإجراء';
    }

    if (statusCode == 409 ||
        message == 'Email is already registered') {
      return 'البريد الإلكتروني مسجل مسبقًا';
    }

    if (statusCode == 400) {
      if (message == 'Google ID Token is required' ||
          message == 'Invalid Google account') {
        return 'تعذر التحقق من حساب Google. حاول مجددًا';
      }

      if (message == 'This email is linked to another Google account') {
        return 'هذا البريد مرتبط بحساب Google آخر';
      }

      return 'البيانات المدخلة غير صحيحة. تحقق منها';
    }

    if (statusCode >= 500) {
      return 'حدث خطأ في الخادم. حاول مرة أخرى لاحقًا';
    }

    return 'تعذر إكمال الطلب. حاول مرة أخرى';
  }
}

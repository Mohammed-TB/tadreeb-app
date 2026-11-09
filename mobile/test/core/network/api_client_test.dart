import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/core/network/token_storage_service.dart';

void main() {
  test(
    'sends JSON and the stored bearer token for authenticated requests',
    () async {
      final tokenStorage = _TestTokenStorage()..token = 'jwt-value';
      final client = ApiClient(
        tokenStorage: tokenStorage,
        baseUrl: 'http://localhost:5000',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/auth/login');
          expect(request.headers['Authorization'], 'Bearer jwt-value');
          expect(jsonDecode(request.body), {'email': 'user@example.com'});
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'token': 'access-token'},
            }),
            200,
          );
        }),
      );

      final response = await client.post(
        '/api/auth/login',
        body: {'email': 'user@example.com'},
        authenticated: true,
      );

      expect(response['success'], isTrue);
    },
  );

  test('maps invalid credentials to an Arabic API error', () async {
    final client = ApiClient(
      tokenStorage: _TestTokenStorage(),
      baseUrl: 'http://localhost:5000',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password',
          }),
          401,
        ),
      ),
    );

    await expectLater(
      client.post('/api/auth/login'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        ),
      ),
    );
  });
}

class _TestTokenStorage extends TokenStorageService {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;
}

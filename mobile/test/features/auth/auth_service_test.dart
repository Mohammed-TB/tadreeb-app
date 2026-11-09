import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/features/auth/models/user_model.dart';
import 'package:project_1/features/auth/services/auth_service.dart';

void main() {
  test('registers with the backend and stores its Tadreeb JWT', () async {
    final tokenStorage = _TestTokenStorage();
    final service = AuthService(
      tokenStorage: tokenStorage,
      apiClient: ApiClient(
        tokenStorage: tokenStorage,
        baseUrl: 'http://localhost:5000',
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/register');
          expect(jsonDecode(request.body), {
            'name': 'New Student',
            'email': 'new@example.com',
            'password': 'password123',
          });
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 'user-1',
                  'name': 'New Student',
                  'email': 'new@example.com',
                  'role': 'student',
                  'status': 'active',
                },
                'token': 'tadreeb-jwt',
              },
            }),
            201,
          );
        }),
      ),
    );

    final user = await service.register(
      name: ' New Student ',
      email: ' New@Example.com ',
      password: 'password123',
    );

    expect(user.id, 'user-1');
    expect(user.role, UserRole.student);
    expect(tokenStorage.token, 'tadreeb-jwt');
  });

  test(
    'restores a user using the stored JWT and current-user endpoint',
    () async {
      final tokenStorage = _TestTokenStorage()..token = 'saved-jwt';
      final service = AuthService(
        tokenStorage: tokenStorage,
        apiClient: ApiClient(
          tokenStorage: tokenStorage,
          baseUrl: 'http://localhost:5000',
          client: MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.path, '/api/auth/me');
            expect(request.headers['Authorization'], 'Bearer saved-jwt');
            return http.Response(
              jsonEncode({
                'success': true,
                'user': {
                  'id': 'user-2',
                  'name': 'Returning Student',
                  'email': 'student@example.com',
                  'role': 'student',
                  'status': 'active',
                  'authProvider': 'google',
                },
              }),
              200,
            );
          }),
        ),
      );

      final user = await service.restoreSession();

      expect(user?.id, 'user-2');
      expect(user?.authProvider, 'google');
    },
  );
}

class _TestTokenStorage extends TokenStorageService {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

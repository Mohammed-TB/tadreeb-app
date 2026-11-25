import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/core/network/token_storage_service.dart';

void main() {
  test('sends If-None-Match and accepts a 304 public response', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['if-none-match'], 'W/"courses-v1"');
      return http.Response('', 304, headers: {'etag': 'W/"courses-v1"'});
    });
    addTearDown(client.close);

    final apiClient = ApiClient(
      tokenStorage: TokenStorageService(),
      client: client,
      baseUrl: 'https://api.example.test',
    );

    final response = await apiClient.getPublic(
      '/api/courses',
      ifNoneMatch: 'W/"courses-v1"',
    );

    expect(response.notModified, isTrue);
    expect(response.data, isNull);
    expect(response.etag, 'W/"courses-v1"');
  });

  test('sends multipart PUT fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/institutes/me/courses/course-1');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data;'),
      );
      final multipartBody = (request as http.Request).body;
      expect(multipartBody, contains('name="title"'));
      expect(multipartBody, contains('Updated course'));
      return http.Response(
        '{"success":true,"data":{}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(client.close);

    final apiClient = ApiClient(
      tokenStorage: TokenStorageService(),
      client: client,
      baseUrl: 'https://api.example.test',
    );

    await apiClient.putMultipart(
      '/api/institutes/me/courses/course-1',
      fields: {'title': 'Updated course'},
      authenticated: false,
    );
  });

  test('hides internal server details from user-facing errors', () async {
    final client = MockClient((_) async {
      return http.Response(
        '{"message":"Green-API configuration is missing"}',
        500,
      );
    });
    addTearDown(client.close);

    final apiClient = ApiClient(
      tokenStorage: TokenStorageService(),
      client: client,
      baseUrl: 'https://api.example.test',
    );

    await expectLater(
      apiClient.get('/api/notifications'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'حدث خطأ في الخادم. حاول مرة أخرى لاحقًا',
        ),
      ),
    );
  });
}

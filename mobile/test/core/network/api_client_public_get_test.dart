import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';

void main() {
  test('sends If-None-Match and accepts a 304 public response', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['if-none-match'], 'W/"courses-v1"');
      return http.Response(
        '',
        304,
        headers: {'etag': 'W/"courses-v1"'},
      );
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
}

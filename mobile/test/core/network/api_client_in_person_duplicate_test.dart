import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/core/network/token_storage_service.dart';

void main() {
  test('explains duplicate in-person registration', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"success":false,"message":"Student already registered for this course with this phone and name"}',
        409,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final apiClient = ApiClient(
      tokenStorage: TokenStorageService(),
      client: client,
      baseUrl: 'https://api.example.test',
    );

    await expectLater(
      apiClient.post('/api/institutes/me/reservations/in-person'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'هذا الطالب مسجل مسبقًا في هذه الدورة بهذا الرقم والاسم',
        ),
      ),
    );
  });
}

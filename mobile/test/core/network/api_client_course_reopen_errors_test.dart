import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/core/network/token_storage_service.dart';

void main() {
  final errors = {
    'Only closed courses can be reopened':
        'لا يمكن إعادة فتح الدورة لأنها ليست مغلقة حاليًا',
    'Course has ended and cannot be reopened':
        'انتهت مدة الدورة، لذلك لا يمكن إعادة فتح التسجيل فيها',
    'Course is full and cannot be reopened':
        'لا يمكن إعادة فتح التسجيل لأن جميع المقاعد محجوزة',
    'Invalid course ID': 'تعذر تحديد الدورة. حدّث قائمة الدورات وحاول مجددًا',
  };

  for (final entry in errors.entries) {
    test('explains course reopen failure: ${entry.key}', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"success":false,"message":"${entry.key}"}',
          400,
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
        apiClient.patch('/api/institutes/me/courses/course-1/reopen'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            entry.value,
          ),
        ),
      );
    });
  }
}

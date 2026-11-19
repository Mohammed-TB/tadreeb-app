import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/features/courses/controllers/course_controller.dart';
import 'package:project_1/features/courses/services/course_service.dart';

void main() {
  test(
    'loads all course categories from the public backend endpoint',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/courses/categories');
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(
          '{"success":true,"data":["تصميم","برمجة"," تصميم ",""]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final service = CourseService(
        apiClient: ApiClient(
          tokenStorage: TokenStorageService(),
          client: client,
          baseUrl: 'https://api.example.test',
        ),
      );
      final controller = CourseController(service);
      addTearDown(controller.dispose);

      await controller.loadCategories();

      expect(controller.courses, isEmpty);
      expect(controller.availableCategories, ['الكل', 'برمجة', 'تصميم']);
      expect(controller.categoriesErrorMessage, isNull);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/features/institutes/controllers/institute_controller.dart';
import 'package:project_1/features/institutes/services/institute_service.dart';

void main() {
  test(
    'filters loaded institutes locally without another API request',
    () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response(
          '''
        {
          "success": true,
          "data": [
            {
              "_id": "institute-1",
              "ownerId": "owner-1",
              "name": "معهد الرياض",
              "address": "الرياض",
              "phone": "0500000001",
              "status": "active"
            },
            {
              "_id": "institute-2",
              "ownerId": "owner-2",
              "name": "معهد جدة",
              "address": "جدة",
              "phone": "0500000002",
              "status": "active"
            }
          ],
          "pagination": {"page": 1, "totalPages": 2, "total": 13}
        }
        ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final controller = InstituteController(
        InstituteService(
          apiClient: ApiClient(
            tokenStorage: TokenStorageService(),
            client: client,
            baseUrl: 'https://api.example.test',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.getInstitutes();
      controller.setSearchQuery('جدة');

      expect(controller.institutes, hasLength(2));
      expect(controller.filteredInstitutes, hasLength(1));
      expect(controller.filteredInstitutes.single.name, 'معهد جدة');
      expect(requestCount, 1);

      controller.setSearchQuery('');
      expect(controller.filteredInstitutes, hasLength(2));
    },
  );
}

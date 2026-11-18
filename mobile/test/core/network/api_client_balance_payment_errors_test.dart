import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/core/network/token_storage_service.dart';

void main() {
  final errors = {
    'Balance payment is not available for this reservation':
        'لا يمكن تسجيل المتبقي الآن؛ تحقق من حالة سند الدفع أو الحجز',
    'Balance payment status changed; please refresh':
        'تغيرت حالة سداد المبلغ المتبقي. حدّث البيانات وحاول مجددًا',
  };

  for (final entry in errors.entries) {
    test('explains balance payment conflict: ${entry.key}', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"success":false,"message":"${entry.key}"}',
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
        apiClient.patch(
          '/api/institutes/me/reservations/reservation-1/balance-payment/in-person',
        ),
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

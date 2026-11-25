import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/features/institutes/services/institute_payment_settings_service.dart';
import 'package:project_1/features/institutes/services/institute_service.dart';

void main() {
  test(
    'caches institute data per owner and refreshes when requested',
    () async {
      var getCount = 0;
      final client = MockClient((request) async {
        if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({'data': _instituteJson('Saved institute')}),
            200,
          );
        }

        getCount++;
        return http.Response(
          jsonEncode({'data': _instituteJson('Institute $getCount')}),
          200,
        );
      });
      addTearDown(client.close);
      final service = InstituteService(
        apiClient: ApiClient(
          tokenStorage: _MemoryTokenStorage(),
          client: client,
          baseUrl: 'https://api.example.test',
        ),
      );

      final first = await service.getMyInstitute(ownerUserId: 'owner-1');
      final cached = await service.getMyInstitute(ownerUserId: 'owner-1');
      expect(first.name, 'Institute 1');
      expect(cached.name, 'Institute 1');
      expect(getCount, 1);

      final otherOwner = await service.getMyInstitute(ownerUserId: 'owner-2');
      expect(otherOwner.name, 'Institute 2');

      await service.updateMyInstitute(
        ownerUserId: 'owner-2',
        name: 'Saved institute',
        description: '',
        phone: '+967777123456',
        email: '',
        address: 'Test City',
      );
      final saved = await service.getMyInstitute(ownerUserId: 'owner-2');
      expect(saved.name, 'Saved institute');
      expect(getCount, 2);

      final refreshed = await service.getMyInstitute(
        ownerUserId: 'owner-2',
        forceRefresh: true,
      );
      expect(refreshed.name, 'Institute 3');
      expect(getCount, 3);
    },
  );

  test('caches payment settings after load and save', () async {
    var getCount = 0;
    final client = MockClient((request) async {
      if (request.method == 'PATCH') {
        return http.Response(
          jsonEncode({
            'data': {
              'receiptResubmissionHours': 12,
              'balancePaymentPolicy': 'installments',
              'minimumInstallmentAmount': 25,
            },
          }),
          200,
        );
      }

      getCount++;
      return http.Response(
        jsonEncode({
          'data': {
            'receiptResubmissionHours': 24,
            'balancePaymentPolicy': 'fullRemainder',
            'minimumInstallmentAmount': getCount * 10,
          },
        }),
        200,
      );
    });
    addTearDown(client.close);
    final service = InstitutePaymentSettingsService(
      apiClient: ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        client: client,
        baseUrl: 'https://api.example.test',
      ),
    );

    final first = await service.getSettings(ownerUserId: 'owner-1');
    final cached = await service.getSettings(ownerUserId: 'owner-1');
    expect(first.minimumInstallmentAmount, 10);
    expect(cached.minimumInstallmentAmount, 10);
    expect(getCount, 1);

    await service.updateSettings(
      ownerUserId: 'owner-1',
      receiptResubmissionHours: 12,
      policy: 'installments',
      minimumInstallmentAmount: 25,
    );
    final saved = await service.getSettings(ownerUserId: 'owner-1');
    expect(saved.balancePaymentPolicy, 'installments');
    expect(saved.minimumInstallmentAmount, 25);
    expect(getCount, 1);

    final refreshed = await service.getSettings(
      ownerUserId: 'owner-1',
      forceRefresh: true,
    );
    expect(refreshed.minimumInstallmentAmount, 20);
    expect(getCount, 2);
  });
}

Map<String, dynamic> _instituteJson(String name) => {
  '_id': 'institute-1',
  'ownerId': 'owner-1',
  'name': name,
  'address': 'Test City',
  'phone': '+967777123456',
  'status': 'active',
};

class _MemoryTokenStorage extends TokenStorageService {
  @override
  Future<String?> readToken() async => 'test-token';
}

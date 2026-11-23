import '../../../core/network/api_client.dart';

class InstitutePaymentSettings {
  const InstitutePaymentSettings({
    required this.balancePaymentPolicy,
    required this.minimumInstallmentAmount,
  });

  final String balancePaymentPolicy;
  final double minimumInstallmentAmount;

  factory InstitutePaymentSettings.fromJson(Map<String, dynamic> json) {
    final policy = json['balancePaymentPolicy']?.toString();
    final minimum = json['minimumInstallmentAmount'];
    if ((policy != 'fullRemainder' && policy != 'installments') ||
        minimum is! num) {
      throw const FormatException('إعدادات الدفعات غير صالحة');
    }
    return InstitutePaymentSettings(
      balancePaymentPolicy: policy!,
      minimumInstallmentAmount: minimum.toDouble(),
    );
  }
}

class InstitutePaymentSettingsService {
  InstitutePaymentSettingsService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<InstitutePaymentSettings> getSettings() async {
    final response = await _apiClient.get(
      '/api/institutes/me/settings',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة إعدادات الدفع');
    }
    return InstitutePaymentSettings.fromJson(data);
  }

  Future<InstitutePaymentSettings> updateSettings({
    required String policy,
    required double minimumInstallmentAmount,
  }) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/settings',
      authenticated: true,
      body: {
        'balancePaymentPolicy': policy,
        if (policy == 'installments')
          'minimumInstallmentAmount': minimumInstallmentAmount,
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر حفظ إعدادات الدفع');
    }
    return InstitutePaymentSettings.fromJson(data);
  }
}

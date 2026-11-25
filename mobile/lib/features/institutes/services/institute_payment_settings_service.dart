import '../../../core/network/api_client.dart';

class InstitutePaymentSettings {
  const InstitutePaymentSettings({
    required this.receiptResubmissionHours,
    required this.balancePaymentPolicy,
    required this.minimumInstallmentAmount,
  });

  final int receiptResubmissionHours;
  final String balancePaymentPolicy;
  final double minimumInstallmentAmount;

  factory InstitutePaymentSettings.fromJson(Map<String, dynamic> json) {
    final policy = json['balancePaymentPolicy']?.toString();
    final minimum = json['minimumInstallmentAmount'];
    final hours = json['receiptResubmissionHours'];
    if ((policy != 'fullRemainder' && policy != 'installments') ||
        minimum is! num ||
        hours is! num ||
        !hours.isFinite ||
        hours.toInt() != hours) {
      throw const FormatException('إعدادات الدفعات غير صالحة');
    }
    return InstitutePaymentSettings(
      receiptResubmissionHours: hours.toInt(),
      balancePaymentPolicy: policy!,
      minimumInstallmentAmount: minimum.toDouble(),
    );
  }
}

class InstitutePaymentSettingsService {
  InstitutePaymentSettingsService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  InstitutePaymentSettings? _cachedSettings;
  String? _cachedSettingsOwnerId;

  Future<InstitutePaymentSettings> getSettings({
    required String ownerUserId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedSettingsOwnerId == ownerUserId &&
        _cachedSettings != null) {
      return _cachedSettings!;
    }

    final response = await _apiClient.get(
      '/api/institutes/me/settings',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة إعدادات الدفع');
    }
    final settings = InstitutePaymentSettings.fromJson(data);
    _cacheSettings(ownerUserId, settings);
    return settings;
  }

  Future<InstitutePaymentSettings> updateSettings({
    required String ownerUserId,
    required int receiptResubmissionHours,
    required String policy,
    required double minimumInstallmentAmount,
  }) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/settings',
      authenticated: true,
      body: {
        'receiptResubmissionHours': receiptResubmissionHours,
        'balancePaymentPolicy': policy,
        'minimumInstallmentAmount': minimumInstallmentAmount,
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر حفظ إعدادات الدفع');
    }
    final settings = InstitutePaymentSettings.fromJson(data);
    _cacheSettings(ownerUserId, settings);
    return settings;
  }

  void _cacheSettings(String ownerUserId, InstitutePaymentSettings settings) {
    _cachedSettingsOwnerId = ownerUserId;
    _cachedSettings = settings;
  }
}

import '../../../core/network/api_client.dart';
import '../models/reservation_model.dart';

class ReservationService {
  ReservationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// جلب جميع حجوزات المعهد: GET /api/institutes/me/reservations
  Future<List<ReservationModel>> getMyReservations() async {
    final response = await _apiClient.get(
      '/api/institutes/me/reservations',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('بيانات الحجوزات غير صالحة');
    }
    return data
        .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> findStudentNameByPhone(String phone) async {
    final response = await _apiClient.get(
      '/api/institutes/me/reservations/student-lookup',
      queryParameters: {'phone': phone},
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('بيانات البحث عن الطالب غير صالحة');
    }

    final studentName = data['studentName'];
    if (studentName == null) return null;
    if (studentName is! String || studentName.trim().isEmpty) {
      throw const FormatException('اسم الطالب المسترجع غير صالح');
    }
    return studentName.trim();
  }

  /// الموافقة على سند الحجز: PATCH /api/institutes/me/reservations/:id/approve
  Future<ReservationModel> approveReservation(String reservationId) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/reservations/$reservationId/approve',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('فشل في إرجاع بيانات الحجز بعد الموافقة');
    }
    return ReservationModel.fromJson(data);
  }

  /// رفض سند الحجز: PATCH /api/institutes/me/reservations/:id/reject
  /// يتطلب في الـ Backend حقل { reason: string } إلزامي
  Future<ReservationModel> rejectReservation(
    String reservationId, {
    required String reason,
  }) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/reservations/$reservationId/reject',
      authenticated: true,
      body: {'reason': reason},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('فشل في إرجاع بيانات الحجز بعد الرفض');
    }
    return ReservationModel.fromJson(data);
  }

  /// الحصول على رابط إيصال السند: GET /api/institutes/me/reservations/:id/receipt
  /// يعود بـ { success: true, data: { receiptUrl: '...' } } أو ما شابه
  Future<String?> getReceiptUrl(String reservationId) async {
    final response = await _apiClient.get(
      '/api/institutes/me/reservations/$reservationId/receipt',
      authenticated: true,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['receiptUrl']?.toString() ?? data['url']?.toString();
    }
    if (data is String) return data;
    return response['url']?.toString();
  }

  Future<ReservationModel> approveBalancePayment(String reservationId) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/reservations/$reservationId/balance-payment/approve',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر اعتماد دفعة الرسوم المتبقية');
    }
    return ReservationModel.fromJson(data);
  }

  Future<ReservationModel> rejectBalancePayment(
    String reservationId, {
    required String reason,
  }) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/reservations/$reservationId/balance-payment/reject',
      authenticated: true,
      body: {'reason': reason},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر رفض سند الدفعة المتبقية');
    }
    return ReservationModel.fromJson(data);
  }

  Future<ReservationModel> recordInPersonBalancePayment(
    String reservationId, {
    required double amount,
  }) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/reservations/$reservationId/balance-payment/in-person',
      authenticated: true,
      body: {'amount': amount},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر تسجيل استلام المبلغ المتبقي');
    }
    return ReservationModel.fromJson(data);
  }

  Future<ReservationModel> recordInPersonTransferPayment({
    required String reservationId,
    required double amount,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/institutes/me/reservations/$reservationId/balance-payment/transfer',
      authenticated: true,
      fields: {'amount': amount.toString()},
      fileBytes: fileBytes,
      fileField: 'receipt',
      fileName: fileName,
      contentType: contentType,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر تسجيل دفعة التحويل');
    }
    return ReservationModel.fromJson(data);
  }

  Future<String?> getPaymentReceiptUrl(String paymentId) async {
    final response = await _apiClient.get(
      '/api/institutes/me/reservations/payments/$paymentId/receipt',
      authenticated: true,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['receiptUrl']?.toString() ?? data['url']?.toString();
    }
    if (data is String) return data;
    return response['url']?.toString();
  }

  Future<String?> getBalancePaymentReceiptUrl(String reservationId) async {
    final response = await _apiClient.get(
      '/api/institutes/me/reservations/$reservationId/balance-payment/receipt',
      authenticated: true,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['receiptUrl']?.toString() ?? data['url']?.toString();
    }
    if (data is String) return data;
    return response['url']?.toString();
  }

  /// تسجيل طالب حضورياً بالمعهد: POST /api/institutes/me/reservations/in-person
  Future<ReservationModel> createInPersonReservation({
    required String courseId,
    required String studentName,
    required String studentPhone,
    required double paymentAmount,
    required String paymentMethod,
    String? studentEnglishName,
    List<int>? receiptBytes,
    String? receiptName,
    String? receiptContentType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/institutes/me/reservations/in-person',
      authenticated: true,
      fields: {
        'courseId': courseId,
        'studentName': studentName,
        'studentPhone': studentPhone,
        'paymentAmount': paymentAmount.toString(),
        'paymentMethod': paymentMethod,
        if (studentEnglishName != null)
          'studentEnglishName': studentEnglishName,
      },
      fileBytes: receiptBytes,
      fileField: receiptBytes == null ? null : 'receipt',
      fileName: receiptName,
      contentType: receiptContentType,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر تسجيل الطالب حضورياً');
    }
    return ReservationModel.fromJson(data);
  }
}

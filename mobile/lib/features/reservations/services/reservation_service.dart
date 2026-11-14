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

  /// تسجيل طالب حضورياً بالمعهد: POST /api/institutes/me/reservations/in-person
  Future<ReservationModel> createInPersonReservation({
    required String courseId,
    required String studentName,
    required String studentPhone,
    required String paymentOption, // full | deposit
    required double amountPaid,
  }) async {
    final response = await _apiClient.post(
      '/api/institutes/me/reservations/in-person',
      authenticated: true,
      body: {
        'courseId': courseId,
        'studentName': studentName,
        'studentPhone': studentPhone,
        'paymentOption': paymentOption,
        'amountPaid': amountPaid,
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر تسجيل الطالب حضورياً');
    }
    return ReservationModel.fromJson(data);
  }
}

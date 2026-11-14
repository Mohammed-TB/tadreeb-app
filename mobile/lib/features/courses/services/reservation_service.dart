import '../../../core/network/api_client.dart';
import '../../students/models/student_reservation_model.dart';

class ReservationService {
  ReservationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// إنشاء حجز إلكتروني: POST /api/reservations
  Future<String> createOnlineReservation({
    required String courseId,
    required String studentName,
    required String studentPhone,
    required String paymentOption,
  }) async {
    final response = await _apiClient.post(
      '/api/reservations',
      authenticated: true,
      body: {
        'courseId': courseId,
        'studentName': studentName,
        'studentPhone': studentPhone,
        'paymentOption': paymentOption,
      },
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات التسجيل');
    }

    final reservationId = data['_id'] ?? data['id'];
    if (reservationId is! String || reservationId.isEmpty) {
      throw const FormatException('لم يُرجع الخادم رقم التسجيل');
    }

    return reservationId;
  }

  /// جلب حجوزات الطالب: GET /api/reservations/my
  Future<List<StudentReservationModel>> getMyReservations() async {
    final response = await _apiClient.get(
      '/api/reservations/my',
      authenticated: true,
    );

    final data = response['data'];
    if (data is! List) {
      throw const FormatException('بيانات حجوزات الطالب غير صالحة');
    }

    return data
        .map((e) => StudentReservationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// رفع أو إعادة رفع سند الدفع: POST /api/reservations/:id/receipt
  Future<void> uploadReceipt({
    required String reservationId,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    await _apiClient.postMultipart(
      '/api/reservations/$reservationId/receipt',
      authenticated: true,
      fields: const {},
      fileBytes: fileBytes,
      fileField: 'receipt',
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// جلب رابط سند الدفع الخاص بالطالب: GET /api/reservations/:id/receipt
  Future<String?> getReceiptUrl(String reservationId) async {
    final response = await _apiClient.get(
      '/api/reservations/$reservationId/receipt',
      authenticated: true,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['receiptUrl']?.toString() ?? data['url']?.toString();
    }
    if (data is String) return data;
    return response['url']?.toString();
  }
}

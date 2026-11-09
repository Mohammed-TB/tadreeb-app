import '../models/enrollment_model.dart';
import '../models/payment_model.dart';
import 'enrollment_repository.dart';

class MockEnrollmentRepository implements EnrollmentRepository {
  final List<EnrollmentModel> _enrollments = [];
  final List<PaymentModel> _payments = [];
  final Map<String, int> _initialEnrolledByCourse = {};

  // Check whether an enrollment currently occupies a seat.
  bool _occupiesSeat(EnrollmentModel enrollment, DateTime now) {
    switch (enrollment.status) {
      case EnrollmentStatus.confirmed:
        return true;

      case EnrollmentStatus.pendingReview:
      case EnrollmentStatus.rejected:
        return enrollment.expiresAt.isAfter(now);

      case EnrollmentStatus.expired:
      case EnrollmentStatus.cancelled:
        return false;
    }
  }

  @override
  Future<List<EnrollmentModel>> getStudentEnrollments(String studentId) async {
    return _enrollments.where((item) => item.studentId == studentId).toList();
  }

  @override
  Future<List<EnrollmentModel>> getInstituteEnrollments(
    String instituteId,
  ) async {
    return _enrollments
        .where((item) => item.instituteId == instituteId)
        .toList();
  }

  // Get all enrollments for a specific course.
  @override
  Future<List<EnrollmentModel>> getCourseEnrollments(String courseId) async {
    return _enrollments.where((item) => item.courseId == courseId).toList();
  }

  @override
  Future<EnrollmentModel?> getEnrollmentById(String enrollmentId) async {
    try {
      return _enrollments.firstWhere((item) => item.id == enrollmentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PaymentModel>> getEnrollmentPayments(String enrollmentId) async {
    return _payments
        .where((item) => item.enrollmentId == enrollmentId)
        .toList();
  }

  @override
  Future<EnrollmentModel> createEnrollment({
    required EnrollmentModel enrollment,
    required PaymentModel payment,
    required int courseCapacity,
    required int currentEnrolled,
  }) async {
    final now = DateTime.now();

    // Validate capacity values.
    if (courseCapacity <= 0 ||
        currentEnrolled < 0 ||
        currentEnrolled > courseCapacity) {
      throw Exception('بيانات سعة الدورة غير صحيحة');
    }

    // Prevent duplicate active bookings.
    final alreadyExists = _enrollments.any(
      (item) =>
          item.studentId == enrollment.studentId &&
          item.courseId == enrollment.courseId &&
          _occupiesSeat(item, now),
    );

    if (alreadyExists) {
      throw Exception('لديك طلب حجز سابق لهذه الدورة');
    }

    // Keep the mock repository's baseline separate from enrollment counts.
    final initialEnrolled = _initialEnrolledByCourse.putIfAbsent(
      enrollment.courseId,
      () =>
          currentEnrolled -
          _enrollments
              .where(
                (item) =>
                    item.courseId == enrollment.courseId &&
                    item.status == EnrollmentStatus.confirmed,
              )
              .length,
    );
    if (initialEnrolled < 0 || initialEnrolled > courseCapacity) {
      throw Exception('بيانات سعة الدورة غير صحيحة');
    }

    final totalOccupiedSeats =
        initialEnrolled +
        _enrollments
            .where(
              (item) =>
                  item.courseId == enrollment.courseId &&
                  _occupiesSeat(item, now),
            )
            .length;

    if (totalOccupiedSeats >= courseCapacity) {
      throw Exception('عذراً، لا توجد مقاعد متاحة حالياً');
    }

    // Validate payment relationship.
    if (payment.enrollmentId != enrollment.id ||
        payment.id != enrollment.currentPaymentId) {
      throw Exception('بيانات عملية الدفع غير متطابقة');
    }

    // Save enrollment and its first payment.
    _enrollments.add(enrollment);
    _payments.add(payment);

    return enrollment;
  }

  @override
  Future<void> updateEnrollment(EnrollmentModel enrollment) async {
    final index = _enrollments.indexWhere((item) => item.id == enrollment.id);

    if (index == -1) {
      throw Exception('الحجز غير موجود');
    }

    _enrollments[index] = enrollment;
  }

  @override
  Future<void> updatePayment(PaymentModel payment) async {
    final index = _payments.indexWhere((item) => item.id == payment.id);

    if (index == -1) {
      throw Exception('عملية الدفع غير موجودة');
    }

    _payments[index] = payment;
  }

  @override
  Future<void> addPayment(PaymentModel payment) async {
    final alreadyExists = _payments.any((item) => item.id == payment.id);

    if (alreadyExists) {
      throw Exception('عملية الدفع موجودة مسبقاً');
    }

    _payments.add(payment);
  }

  @override
  Future<List<EnrollmentModel>> expireOverdueEnrollments() async {
    final now = DateTime.now();
    final expiredEnrollments = <EnrollmentModel>[];

    for (var i = 0; i < _enrollments.length; i++) {
      final enrollment = _enrollments[i];

      final canExpire =
          enrollment.status == EnrollmentStatus.pendingReview ||
          enrollment.status == EnrollmentStatus.rejected;

      if (canExpire && !enrollment.expiresAt.isAfter(now)) {
        final expiredEnrollment = enrollment.copyWith(
          status: EnrollmentStatus.expired,
        );

        _enrollments[i] = expiredEnrollment;
        expiredEnrollments.add(expiredEnrollment);
      }
    }

    return expiredEnrollments;
  }
}

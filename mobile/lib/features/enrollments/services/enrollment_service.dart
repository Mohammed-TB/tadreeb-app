
import '../../courses/models/course_model.dart';
import '../models/booking_settings_model.dart';
import '../models/enrollment_model.dart';
import '../models/payment_model.dart';
import '../repositories/enrollment_repository.dart';

class EnrollmentService {
  final EnrollmentRepository _repository;

  EnrollmentService({
    required EnrollmentRepository repository,
  }) : _repository = repository;

  // Create a new booking and its first payment.
  Future<EnrollmentModel> createEnrollment({
    required String studentId,
    required CourseModel course,
    required PaymentType paymentType,
    required String receiptUrl,
    required BookingSettingsModel settings,
  }) async {
    final now = DateTime.now();

    if (receiptUrl.trim().isEmpty) {
      throw Exception('يرجى إرفاق سند التحويل');
    }

    final amount = PaymentCalculator.calculateAmount(
      course: course,
      paymentType: paymentType,
    );

    if (amount <= 0 || amount > course.price) {
      throw Exception('مبلغ الدفع غير صالح');
    }

    final enrollmentId = 'enrollment_${now.microsecondsSinceEpoch}';
    final paymentId = 'payment_${now.microsecondsSinceEpoch}';

    final enrollment = EnrollmentModel(
      id: enrollmentId,
      studentId: studentId,
      courseId: course.id,
      instituteId: course.instituteID,
      coursePrice: course.price,
      depositPercentage: course.depositPercentage,
      amountToPay: amount,
      currentPaymentId: paymentId,
      status: EnrollmentStatus.pendingReview,
      createdAt: now,
      expiresAt: now.add(
        Duration(hours: settings.reviewDurationHours),
      ),
    );

    final payment = PaymentModel(
      id: paymentId,
      enrollmentId: enrollmentId,
      type: paymentType,
      amount: amount,
      receiptUrl: receiptUrl,
      submittedAt: now,
    );

    return _repository.createEnrollment(
      enrollment: enrollment,
      payment: payment,
      courseCapacity: course.capacity,
      currentEnrolled: course.enrolled,
    );
  }

  // Approve the current payment.
  Future<EnrollmentModel> approvePayment({
    required String enrollmentId,
  }) async {
    final enrollment = await _getEnrollment(enrollmentId);

    if (enrollment.status != EnrollmentStatus.pendingReview) {
      throw Exception('الحجز ليس قيد المراجعة');
    }

    if (await _expireIfOverdue(enrollment)) {
      throw Exception('انتهت مهلة مراجعة الحجز وتم انتهاء الحجز');
    }

    final payment = await _getCurrentPayment(enrollment);

    if (payment.status != PaymentStatus.pendingReview) {
      throw Exception('عملية الدفع تمت مراجعتها مسبقاً');
    }

    if (payment.amount > enrollment.remainingAmount) {
      throw Exception('مبلغ الدفع يتجاوز المبلغ المتبقي');
    }

    final now = DateTime.now();

    final updatedPayment = payment.copyWith(
      status: PaymentStatus.approved,
      reviewedAt: now,
      clearRejectionReason: true,
    );

    final updatedEnrollment = enrollment.copyWith(
      paidAmount: enrollment.paidAmount + payment.amount,
      status: EnrollmentStatus.confirmed,
      confirmedAt: now,
      clearRejectionReason: true,
    );

    await _repository.updatePayment(updatedPayment);
    await _repository.updateEnrollment(updatedEnrollment);

    return updatedEnrollment;
  }

  // Reject the current payment.
  Future<EnrollmentModel> rejectPayment({
    required String enrollmentId,
    required String reason,
    required BookingSettingsModel settings,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('يرجى كتابة سبب الرفض');
    }

    final enrollment = await _getEnrollment(enrollmentId);

    if (enrollment.status != EnrollmentStatus.pendingReview) {
      throw Exception('الحجز ليس قيد المراجعة');
    }

    if (await _expireIfOverdue(enrollment)) {
      throw Exception('انتهت مهلة مراجعة الحجز وتم انتهاء الحجز');
    }

    final payment = await _getCurrentPayment(enrollment);

    if (payment.status != PaymentStatus.pendingReview) {
      throw Exception('عملية الدفع تمت مراجعتها مسبقاً');
    }

    final now = DateTime.now();

    final updatedPayment = payment.copyWith(
      status: PaymentStatus.rejected,
      reviewedAt: now,
      rejectionReason: reason.trim(),
    );

    final updatedEnrollment = enrollment.copyWith(
      status: EnrollmentStatus.rejected,
      expiresAt: now.add(
        Duration(hours: settings.resubmissionDurationHours),
      ),
      lastRejectionReason: reason.trim(),
    );

    await _repository.updatePayment(updatedPayment);
    await _repository.updateEnrollment(updatedEnrollment);

    return updatedEnrollment;
  }

  // Resubmit payment after rejection.
  Future<EnrollmentModel> resubmitPayment({
    required String enrollmentId,
    required String receiptUrl,
    required PaymentType paymentType,
    required BookingSettingsModel settings,
  }) async {
    if (receiptUrl.trim().isEmpty) {
      throw Exception('يرجى إرفاق سند التحويل');
    }

    final enrollment = await _getEnrollment(enrollmentId);

    if (enrollment.status != EnrollmentStatus.rejected) {
      throw Exception('لا يمكن إعادة إرسال السند لهذا الحجز');
    }

    if (await _expireIfOverdue(enrollment)) {
      throw Exception('انتهت مهلة إعادة إرسال السند وتم انتهاء الحجز');
    }

    final maxAttempts = settings.maxResubmissionAttempts;

    if (maxAttempts != null &&
        enrollment.resubmissionCount >= maxAttempts) {
      throw Exception('تجاوزت الحد المسموح لمحاولات إعادة الإرسال');
    }

    final now = DateTime.now();

    final amount = paymentType == PaymentType.full
        ? enrollment.remainingAmount
        : (enrollment.coursePrice *
                enrollment.depositPercentage /
                100)
            .roundToDouble();

    if (amount <= 0 || amount > enrollment.remainingAmount) {
      throw Exception('مبلغ الدفع غير صالح');
    }

    final paymentId =
    'payment_${now.microsecondsSinceEpoch}_${enrollment.resubmissionCount + 1}';

    final newPayment = PaymentModel(
      id: paymentId,
      enrollmentId: enrollment.id,
      type: paymentType,
      amount: amount,
      receiptUrl: receiptUrl,
      submittedAt: now,
    );

    final updatedEnrollment = enrollment.copyWith(
      currentPaymentId: paymentId,
      status: EnrollmentStatus.pendingReview,
      expiresAt: now.add(
        Duration(hours: settings.reviewDurationHours),
      ),
      resubmissionCount: enrollment.resubmissionCount + 1,
      clearRejectionReason: true,
    );

    // Preserve all previous payment attempts.
    await _repository.addPayment(newPayment);
    await _repository.updateEnrollment(updatedEnrollment);

    return updatedEnrollment;
  }

  // Expire an enrollment if its deadline has passed.
  Future<bool> _expireIfOverdue(
    EnrollmentModel enrollment,
  ) async {
    final isActive =
        enrollment.status == EnrollmentStatus.pendingReview ||
        enrollment.status == EnrollmentStatus.rejected;

    if (!isActive || enrollment.expiresAt.isAfter(DateTime.now())) {
      return false;
    }

    final expiredEnrollment = enrollment.copyWith(
      status: EnrollmentStatus.expired,
    );

    await _repository.updateEnrollment(expiredEnrollment);

    return true;
  }

  // Get an enrollment.
  Future<EnrollmentModel> _getEnrollment(
    String enrollmentId,
  ) async {
    final enrollment = await _repository.getEnrollmentById(
      enrollmentId,
    );

    if (enrollment == null) {
      throw Exception('الحجز غير موجود');
    }

    return enrollment;
  }

  // Get the current payment.
  Future<PaymentModel> _getCurrentPayment(
    EnrollmentModel enrollment,
  ) async {
    final paymentId = enrollment.currentPaymentId;

    if (paymentId == null) {
      throw Exception('لا توجد عملية دفع مرتبطة بالحجز');
    }

    final payments = await _repository.getEnrollmentPayments(
      enrollment.id,
    );

    try {
      return payments.firstWhere(
        (item) => item.id == paymentId,
      );
    } catch (_) {
      throw Exception('عملية الدفع غير موجودة');
    }
  }
}

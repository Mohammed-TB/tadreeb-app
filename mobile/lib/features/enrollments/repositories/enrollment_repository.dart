
import '../models/enrollment_model.dart';
import '../models/payment_model.dart';

abstract class EnrollmentRepository {
  // Fetch enrollments.
  Future<List<EnrollmentModel>> getStudentEnrollments(
    String studentId,
  );

  Future<List<EnrollmentModel>> getInstituteEnrollments(
    String instituteId,
  );

  Future<EnrollmentModel?> getEnrollmentById(
    String enrollmentId,
  );

  // Fetch payment attempts.
  Future<List<PaymentModel>> getEnrollmentPayments(
    String enrollmentId,
  );

  // Create enrollment with its first payment.
  Future<EnrollmentModel> createEnrollment({
    required EnrollmentModel enrollment,
    required PaymentModel payment,
    required int courseCapacity,
    required int currentEnrolled,
  });

  // Update enrollment.
  Future<void> updateEnrollment(EnrollmentModel enrollment);

  // Update an existing payment.
  Future<void> updatePayment(PaymentModel payment);

  // Add a new payment attempt.
  Future<void> addPayment(PaymentModel payment);

  // Expire all overdue active enrollments.
  Future<List<EnrollmentModel>> expireOverdueEnrollments();

  Future<List<EnrollmentModel>> getCourseEnrollments(
  String courseId,
);
}

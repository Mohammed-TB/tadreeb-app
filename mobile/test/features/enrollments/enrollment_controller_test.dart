import 'package:flutter_test/flutter_test.dart';

import 'package:project_1/features/courses/controllers/course_controller.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/services/course_service.dart';
import 'package:project_1/features/enrollments/controllers/enrollment_controller.dart';
import 'package:project_1/features/enrollments/models/booking_settings_model.dart';
import 'package:project_1/features/enrollments/models/enrollment_model.dart';
import 'package:project_1/features/enrollments/models/payment_model.dart';
import 'package:project_1/features/enrollments/repositories/mock_enrollment_repository.dart';
import 'package:project_1/features/enrollments/services/enrollment_service.dart';

void main() {
  late MockEnrollmentRepository repository;
  late EnrollmentController enrollmentController;
  late CourseController courseController;
  late CourseModel course;

  const settings = BookingSettingsModel();

  setUp(() async {
    repository = MockEnrollmentRepository();

    courseController = CourseController(CourseService());
    await courseController.getCourses();

    enrollmentController = EnrollmentController(
      EnrollmentService(repository: repository),
      repository,
      courseController,
    );

    course = courseController.courses.first;
  });

  group('EnrollmentController - Course Seats Integration', () {
    test('creating enrollment reserves one seat', () async {
      final initialEnrolled = course.enrolled;
      final initialReserved = course.reservedSeats;

      final success = await enrollmentController.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      expect(success, isTrue);

      final updatedCourse = courseController.getCourseById(course.id)!;

      expect(updatedCourse.enrolled, initialEnrolled);
      expect(updatedCourse.reservedSeats, initialReserved + 1);

      expect(updatedCourse.availableSeats, course.availableSeats - 1);
    });

    test('rejecting payment keeps the seat reserved', () async {
      await enrollmentController.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      final enrollment = enrollmentController.studentEnrollments.first;

      final success = await enrollmentController.rejectPayment(
        enrollmentId: enrollment.id,
        reason: 'Receipt is unclear',
        settings: settings,
      );

      expect(success, isTrue);

      final updatedCourse = courseController.getCourseById(course.id)!;

      expect(updatedCourse.reservedSeats, 1);
      expect(updatedCourse.enrolled, course.enrolled);

      final rejectedEnrollment = await repository.getEnrollmentById(
        enrollment.id,
      );
      final rejectedPayments = await repository.getEnrollmentPayments(
        enrollment.id,
      );

      expect(rejectedEnrollment?.status, EnrollmentStatus.rejected);
      expect(rejectedEnrollment?.lastRejectionReason, 'Receipt is unclear');
      expect(rejectedPayments.single.status, PaymentStatus.rejected);
      expect(rejectedPayments.single.rejectionReason, 'Receipt is unclear');
    });

    test(
      'rejecting payment reports invalid reasons without changing state',
      () async {
        await enrollmentController.createEnrollment(
          studentId: 'student_1',
          course: course,
          paymentType: PaymentType.deposit,
          receiptUrl: 'mock://receipt.jpg',
          settings: settings,
        );

        final enrollment = enrollmentController.studentEnrollments.first;
        final success = await enrollmentController.rejectPayment(
          enrollmentId: enrollment.id,
          reason: '   ',
          settings: settings,
        );

        expect(success, isFalse);
        expect(enrollmentController.errorMessage, contains('سبب الرفض'));
        expect(
          (await repository.getEnrollmentById(enrollment.id))?.status,
          EnrollmentStatus.pendingReview,
        );
      },
    );

    test('approving payment moves seat from reserved to enrolled', () async {
      await enrollmentController.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      final enrollment = enrollmentController.studentEnrollments.first;

      final success = await enrollmentController.approvePayment(enrollment.id);

      expect(success, isTrue);

      final updatedCourse = courseController.getCourseById(course.id)!;

      expect(updatedCourse.enrolled, course.enrolled + 1);
      expect(updatedCourse.reservedSeats, 0);
    });

    test('refreshing counts repeatedly does not duplicate seats', () async {
      await enrollmentController.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      await enrollmentController.getStudentEnrollments('student_1');
      await enrollmentController.getStudentEnrollments('student_1');

      final updatedCourse = courseController.getCourseById(course.id)!;

      expect(updatedCourse.enrolled, course.enrolled);
      expect(updatedCourse.reservedSeats, 1);
    });

    test('expired enrollment releases its reserved seat', () async {
      final now = DateTime.now();

      final enrollment = EnrollmentModel(
        id: 'expired_enrollment',
        studentId: 'student_1',
        courseId: course.id,
        instituteId: course.instituteID,
        coursePrice: course.price,
        depositPercentage: course.depositPercentage,
        amountToPay: course.depositAmount,
        currentPaymentId: 'expired_payment',
        status: EnrollmentStatus.pendingReview,
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      final payment = PaymentModel(
        id: 'expired_payment',
        enrollmentId: enrollment.id,
        type: PaymentType.deposit,
        amount: course.depositAmount,
        receiptUrl: 'mock://receipt.jpg',
        submittedAt: enrollment.createdAt,
      );

      await repository.createEnrollment(
        enrollment: enrollment,
        payment: payment,
        courseCapacity: course.capacity,
        currentEnrolled: course.enrolled,
      );

      await enrollmentController.getStudentEnrollments('student_1');

      final savedEnrollment = await repository.getEnrollmentById(enrollment.id);

      final updatedCourse = courseController.getCourseById(course.id)!;

      expect(savedEnrollment!.status, EnrollmentStatus.expired);
      expect(updatedCourse.reservedSeats, 0);
      expect(updatedCourse.enrolled, course.enrolled);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/enrollments/models/booking_settings_model.dart';
import 'package:project_1/features/enrollments/models/enrollment_model.dart';
import 'package:project_1/features/enrollments/models/payment_model.dart';
import 'package:project_1/features/enrollments/repositories/mock_enrollment_repository.dart';
import 'package:project_1/features/enrollments/services/enrollment_service.dart';

void main() {
  late MockEnrollmentRepository repository;
  late EnrollmentService service;
  late CourseModel course;
  late BookingSettingsModel settings;

  setUp(() {
    repository = MockEnrollmentRepository();

    service = EnrollmentService(repository: repository);

    course = CourseModel(
      id: 'course_1',
      instituteID: 'institute_1',
      name: 'Flutter Development',
      description: 'Flutter course',
      price: 1000,
      category: 'Programming',
      capacity: 10,
      enrolled: 0,
      depositPercentage: 30,
    );

    settings = const BookingSettingsModel();
  });

  group('EnrollmentService - Create Enrollment', () {
    test('creates a new enrollment with pending review status', () async {
      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      expect(enrollment.studentId, 'student_1');
      expect(enrollment.courseId, course.id);
      expect(enrollment.instituteId, course.instituteID);
      expect(enrollment.status, EnrollmentStatus.pendingReview);
      expect(enrollment.amountToPay, 300);
      expect(enrollment.currentPaymentId, isNotNull);

      final payments = await repository.getEnrollmentPayments(enrollment.id);

      expect(payments, hasLength(1));
      expect(payments.first.amount, 300);
      expect(payments.first.status, PaymentStatus.pendingReview);
    });

    test('rejects enrollment when receipt is empty', () async {
      await expectLater(
        service.createEnrollment(
          studentId: 'student_1',
          course: course,
          paymentType: PaymentType.deposit,
          receiptUrl: '   ',
          settings: settings,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects enrollment when course is full', () async {
      final fullCourse = CourseModel(
        id: 'course_full',
        instituteID: 'institute_1',
        name: 'Full Course',
        description: 'Full course',
        price: 1000,
        category: 'Programming',
        capacity: 10,
        enrolled: 10,
      );

      await expectLater(
        service.createEnrollment(
          studentId: 'student_1',
          course: fullCourse,
          paymentType: PaymentType.deposit,
          receiptUrl: 'mock://receipt.jpg',
          settings: settings,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'prevents booking when no seats remain after another booking',
      () async {
        final limitedCourse = CourseModel(
          id: 'limited_course',
          instituteID: 'institute_1',
          name: 'Limited Course',
          description: 'Limited seats',
          price: 1000,
          category: 'Programming',
          capacity: 1,
          enrolled: 0,
        );

        await service.createEnrollment(
          studentId: 'student_1',
          course: limitedCourse,
          paymentType: PaymentType.deposit,
          receiptUrl: 'mock://receipt1.jpg',
          settings: settings,
        );

        await expectLater(
          service.createEnrollment(
            studentId: 'student_2',
            course: limitedCourse,
            paymentType: PaymentType.deposit,
            receiptUrl: 'mock://receipt2.jpg',
            settings: settings,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'does not count a confirmed booking twice when checking capacity',
      () async {
        final limitedCourse = CourseModel(
          id: 'course_two_seats',
          instituteID: 'institute_1',
          name: 'Two Seat Course',
          description: 'Two seats available',
          price: 1000,
          category: 'Programming',
          capacity: 2,
          enrolled: 0,
        );

        final firstEnrollment = await service.createEnrollment(
          studentId: 'student_1',
          course: limitedCourse,
          paymentType: PaymentType.deposit,
          receiptUrl: 'mock://receipt1.jpg',
          settings: settings,
        );
        await repository.updateEnrollment(
          firstEnrollment.copyWith(status: EnrollmentStatus.confirmed),
        );

        final secondEnrollment = await service.createEnrollment(
          studentId: 'student_2',
          course: limitedCourse.copyWith(enrolled: 1),
          paymentType: PaymentType.deposit,
          receiptUrl: 'mock://receipt2.jpg',
          settings: settings,
        );

        expect(secondEnrollment.status, EnrollmentStatus.pendingReview);
        await expectLater(
          service.createEnrollment(
            studentId: 'student_3',
            course: limitedCourse.copyWith(enrolled: 1),
            paymentType: PaymentType.deposit,
            receiptUrl: 'mock://receipt3.jpg',
            settings: settings,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('EnrollmentService - Approve Payment', () {
    test('approves payment and confirms enrollment', () async {
      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      final result = await service.approvePayment(enrollmentId: enrollment.id);

      expect(result.status, EnrollmentStatus.confirmed);
      expect(result.paidAmount, 300);
      expect(result.confirmedAt, isNotNull);

      final payments = await repository.getEnrollmentPayments(enrollment.id);

      expect(payments.first.status, PaymentStatus.approved);
      expect(payments.first.reviewedAt, isNotNull);
    });

    test('cannot approve the same enrollment twice', () async {
      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      await service.approvePayment(enrollmentId: enrollment.id);

      await expectLater(
        service.approvePayment(enrollmentId: enrollment.id),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('EnrollmentService - Reject Payment', () {
    test('rejects payment and stores rejection reason', () async {
      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      final result = await service.rejectPayment(
        enrollmentId: enrollment.id,
        reason: 'Receipt is unclear',
        settings: settings,
      );

      expect(result.status, EnrollmentStatus.rejected);
      expect(result.lastRejectionReason, 'Receipt is unclear');

      final payments = await repository.getEnrollmentPayments(enrollment.id);

      expect(payments.first.status, PaymentStatus.rejected);
      expect(payments.first.rejectionReason, 'Receipt is unclear');
    });

    test('rejects an empty rejection reason', () async {
      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt.jpg',
        settings: settings,
      );

      await expectLater(
        service.rejectPayment(
          enrollmentId: enrollment.id,
          reason: '   ',
          settings: settings,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('EnrollmentService - Resubmit Payment', () {
    test('resubmits payment and preserves previous attempts', () async {
      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt1.jpg',
        settings: settings,
      );

      await service.rejectPayment(
        enrollmentId: enrollment.id,
        reason: 'Receipt is unclear',
        settings: settings,
      );

      final updatedEnrollment = await service.resubmitPayment(
        enrollmentId: enrollment.id,
        receiptUrl: 'mock://receipt2.jpg',
        paymentType: PaymentType.deposit,
        settings: settings,
      );

      expect(updatedEnrollment.status, EnrollmentStatus.pendingReview);

      expect(updatedEnrollment.resubmissionCount, 1);
      expect(updatedEnrollment.currentPaymentId, isNotNull);
      expect(updatedEnrollment.lastRejectionReason, isNull);

      final payments = await repository.getEnrollmentPayments(enrollment.id);

      expect(payments, hasLength(2));
      expect(payments.first.status, PaymentStatus.rejected);
      expect(payments.last.status, PaymentStatus.pendingReview);
      expect(updatedEnrollment.currentPaymentId, payments.last.id);
    });

    test('rejects resubmission when attempts limit is reached', () async {
      const limitedSettings = BookingSettingsModel(maxResubmissionAttempts: 1);

      final enrollment = await service.createEnrollment(
        studentId: 'student_1',
        course: course,
        paymentType: PaymentType.deposit,
        receiptUrl: 'mock://receipt1.jpg',
        settings: limitedSettings,
      );

      await service.rejectPayment(
        enrollmentId: enrollment.id,
        reason: 'First rejection',
        settings: limitedSettings,
      );

      final updatedEnrollment = await service.resubmitPayment(
        enrollmentId: enrollment.id,
        receiptUrl: 'mock://receipt2.jpg',
        paymentType: PaymentType.deposit,
        settings: limitedSettings,
      );

      await service.rejectPayment(
        enrollmentId: updatedEnrollment.id,
        reason: 'Second rejection',
        settings: limitedSettings,
      );

      await expectLater(
        service.resubmitPayment(
          enrollmentId: enrollment.id,
          receiptUrl: 'mock://receipt3.jpg',
          paymentType: PaymentType.deposit,
          settings: limitedSettings,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('EnrollmentService - Expiration', () {
    test('expires enrollment when review deadline has passed', () async {
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

      await expectLater(
        service.approvePayment(enrollmentId: enrollment.id),
        throwsA(isA<Exception>()),
      );

      final savedEnrollment = await repository.getEnrollmentById(enrollment.id);

      expect(savedEnrollment!.status, EnrollmentStatus.expired);
    });
  });
}

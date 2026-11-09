import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_1/core/mock_data/courses_data.dart';
import 'package:project_1/core/mock_data/institutes_data.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/auth/models/user_model.dart';
import 'package:project_1/features/auth/services/auth_service.dart';
import 'package:project_1/features/courses/controllers/course_controller.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/services/course_service.dart';
import 'package:project_1/features/enrollments/controllers/enrollment_controller.dart';
import 'package:project_1/features/enrollments/models/enrollment_model.dart';
import 'package:project_1/features/enrollments/models/payment_model.dart';
import 'package:project_1/features/enrollments/repositories/mock_enrollment_repository.dart';
import 'package:project_1/features/enrollments/services/enrollment_service.dart';
import 'package:project_1/features/institutes/controllers/institute_controller.dart';
import 'package:project_1/features/institutes/models/institute_model.dart';
import 'package:project_1/features/institutes/screens/institute_bookings_screen.dart';
import 'package:project_1/features/institutes/services/institute_service.dart';

void main() {
  testWidgets('reject action validates and submits the rejection reason', (
    tester,
  ) async {
    final authController = AuthController(
      _TestAuthService(
        const UserModel(
          id: 'user1',
          name: 'John Doe',
          email: 'john@example.com',
          role: UserRole.instituteOwner,
        ),
      ),
    );
    await authController.login(
      email: 'john@example.com',
      password: 'password123',
    );

    final courseController = CourseController(_ImmediateCourseService());
    await courseController.getCourses();
    final instituteController = InstituteController(
      _ImmediateInstituteService(),
    );
    await instituteController.getInstitutes();
    final repository = MockEnrollmentRepository();
    final service = EnrollmentService(repository: repository);
    final enrollmentController = EnrollmentController(
      service,
      repository,
      courseController,
    );
    final course = courseController.courses.first;
    final now = DateTime.now();
    final enrollment = EnrollmentModel(
      id: 'test-enrollment',
      studentId: 'user2',
      courseId: course.id,
      instituteId: course.instituteID,
      coursePrice: course.price,
      depositPercentage: course.depositPercentage,
      amountToPay: course.depositAmount,
      currentPaymentId: 'test-payment',
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 2)),
    );
    await repository.createEnrollment(
      enrollment: enrollment,
      payment: PaymentModel(
        id: 'test-payment',
        enrollmentId: enrollment.id,
        type: PaymentType.deposit,
        amount: enrollment.amountToPay,
        receiptUrl: 'mock://receipt.jpg',
        submittedAt: now,
      ),
      courseCapacity: course.capacity,
      currentEnrolled: course.enrolled,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: courseController),
          ChangeNotifierProvider.value(value: instituteController),
          ChangeNotifierProvider.value(value: enrollmentController),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InstituteBookingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Development'), findsOneWidget);
    await tester.tap(find.text('رفض السند مع توضيح السبب'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تأكيد الرفض'));
    await tester.pumpAndSettle();
    expect(find.text('سبب الرفض مطلوب'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'الصورة غير واضحة');
    await tester.tap(find.text('تأكيد الرفض'));
    await tester.pumpAndSettle();

    expect(find.text('تم رفض الطلب وإرسال السبب للطالب'), findsOneWidget);
    expect(
      (await repository.getEnrollmentById(enrollment.id))?.status,
      EnrollmentStatus.rejected,
    );
    final payment = (await repository.getEnrollmentPayments(
      enrollment.id,
    )).single;
    expect(payment.status, PaymentStatus.rejected);
    expect(payment.rejectionReason, 'الصورة غير واضحة');
  });
}

class _TestAuthService extends AuthService {
  _TestAuthService(this.user);

  final UserModel user;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async => user;
}

class _ImmediateCourseService extends CourseService {
  @override
  Future<List<CourseModel>> getCourses() async => courses;
}

class _ImmediateInstituteService extends InstituteService {
  @override
  Future<List<InstituteModel>> getInstitutes() async => institutes;
}

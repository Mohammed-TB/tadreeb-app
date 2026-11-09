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
import 'package:project_1/features/enrollments/repositories/mock_enrollment_repository.dart';
import 'package:project_1/features/enrollments/services/enrollment_service.dart';
import 'package:project_1/features/institutes/controllers/institute_controller.dart';
import 'package:project_1/features/institutes/models/institute_model.dart';
import 'package:project_1/features/institutes/services/institute_service.dart';
import 'package:project_1/features/students/screens/course_registration_screen.dart';

void main() {
  testWidgets('registration flow is split into navigable steps', (
    tester,
  ) async {
    final authController = AuthController(
      _TestAuthService(
        const UserModel(
          id: 'user2',
          name: 'Jane Smith',
          email: 'jane@example.com',
        ),
      ),
    );
    await authController.login(
      email: 'jane@example.com',
      password: 'password456',
    );
    final courseController = CourseController(_CourseService());
    await courseController.getCourses();
    final instituteController = InstituteController(_InstituteService());
    await instituteController.getInstitutes();
    final repository = MockEnrollmentRepository();
    final enrollmentController = EnrollmentController(
      EnrollmentService(repository: repository),
      repository,
      courseController,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: courseController),
          ChangeNotifierProvider.value(value: instituteController),
          ChangeNotifierProvider.value(value: enrollmentController),
        ],
        child: MaterialApp(
          home: CourseRegistrationScreen(course: courses.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('راجع بيانات التسجيل'), findsOneWidget);
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.text('اختر طريقة الدفع'), findsOneWidget);
    expect(find.text('دفع العربون'), findsOneWidget);

    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.text('أرفق سند التحويل'), findsOneWidget);
    expect(find.text('إرسال طلب التسجيل'), findsOneWidget);
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

class _CourseService extends CourseService {
  @override
  Future<List<CourseModel>> getCourses() async => courses;
}

class _InstituteService extends InstituteService {
  @override
  Future<List<InstituteModel>> getInstitutes() async => institutes;
}

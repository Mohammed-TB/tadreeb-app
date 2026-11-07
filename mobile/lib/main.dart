import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';

import 'features/courses/controllers/course_controller.dart';
import 'features/courses/services/course_service.dart';

import 'features/institutes/controllers/institute_controller.dart';
import 'features/institutes/services/institute_service.dart';

import 'features/enrollments/repositories/enrollment_repository.dart';
import 'features/enrollments/repositories/mock_enrollment_repository.dart';
import 'features/enrollments/services/enrollment_service.dart';
import 'features/enrollments/controllers/enrollment_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Authentication
        ChangeNotifierProvider(create: (_) => AuthController(AuthService())),

        // Courses
        ChangeNotifierProvider(
          create: (_) => CourseController(CourseService())..getCourses(),
        ),

        // Institutes
        ChangeNotifierProvider(
          create: (_) =>
              InstituteController(InstituteService())..getInstitutes(),
        ),

        // Enrollment Repository
        Provider<EnrollmentRepository>(
          create: (_) => MockEnrollmentRepository(),
        ),

        // Enrollment Service
        Provider<EnrollmentService>(
          create: (context) => EnrollmentService(
            repository: context.read<EnrollmentRepository>(),
          ),
        ),

        // Enrollment Controller
        ChangeNotifierProvider(
          create: (context) => EnrollmentController(
            context.read<EnrollmentService>(),
            context.read<EnrollmentRepository>(),
            context.read<CourseController>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

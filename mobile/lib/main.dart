import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';
import 'features/courses/controllers/course_controller.dart';
import 'features/courses/services/course_service.dart';
import 'features/institutes/controllers/institute_controller.dart';
import 'features/institutes/services/institute_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseController(CourseService())..getCourses(),
        ),
        ChangeNotifierProvider(
            create: (_) => InstituteController(InstituteService())..getInstitutes(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
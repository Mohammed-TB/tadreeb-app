
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:project_1/features/onboarding/screens/onboarding_screen.dart';

import '../core/routing/main_shell.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/courses/models/course_model.dart';
import '../features/students/screens/course_details_screen.dart';
import '../features/students/screens/courses_screen.dart';
import '../features/students/screens/home_screen.dart';

import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      // صفحات المصادقة والتعريف
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // تفاصيل الدورة
      GoRoute(
        path: '/course-details',
        builder: (context, state) {
          final course = state.extra as CourseModel;
          return CourseDetailsScreen(course: course);
        },
      ),

      // الصفحات الرئيسية مع BottomNavigationBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home_screen',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courses_screen',
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      // اللغة العربية
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,

      // نظام التصميم الموحد
      theme: AppTheme.light,

      // التنقل
      routerConfig: router,
    );
  }
}

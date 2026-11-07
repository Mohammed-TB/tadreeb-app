import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../features/students/routing/student_shell.dart';
import '../features/students/screens/bookings_screen.dart';
import '../features/institutes/routing/institute_shell.dart';
import '../features/institutes/screens/institute_bookings_screen.dart';
import '../features/institutes/screens/institute_courses_screen.dart';
import '../features/institutes/screens/institute_students_screen.dart';
import '../features/admin/routing/admin_shell.dart';
import '../features/admin/screens/admin_institutes_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_more_screen.dart';

// Authentication
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

// Onboarding
import '../features/onboarding/screens/onboarding_screen.dart';

// Courses
import '../features/courses/models/course_model.dart';
import '../features/students/screens/course_details_screen.dart';
import '../features/students/screens/courses_screen.dart';
import '../features/students/screens/home_screen.dart';

// Institute
import '../features/institutes/screens/institute_dashboard_screen.dart';

// Admin
import '../features/admin/screens/admin_dashboard_screen.dart';

// Theme
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      // Authentication
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Course Details
      GoRoute(
        path: '/course-details',
        builder: (context, state) {
          final course = state.extra as CourseModel;
          return CourseDetailsScreen(course: course);
        },
      ),

      // Institute Owner Dashboard
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return InstituteShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/institute_dashboard',
                builder: (context, state) => const InstituteDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/institute_bookings',
                builder: (context, state) => const InstituteBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/institute_courses',
                builder: (context, state) => const InstituteCoursesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/institute_students',
                builder: (context, state) => const InstituteStudentsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Platform Admin Dashboard
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin_dashboard',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin_institutes',
                builder: (context, state) => const AdminInstitutesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin_users',
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin_more',
                builder: (context, state) => const AdminMoreScreen(),
              ),
            ],
          ),
        ],
      ),
      // Student Dashboard with Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home_screen',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Courses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courses_screen',
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings_screen',
                builder: (context, state) => const BookingsScreen(),
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

      // Arabic Localization
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,

      // App Theme
      theme: AppTheme.light,

      // Navigation
      routerConfig: router,
    );
  }
}

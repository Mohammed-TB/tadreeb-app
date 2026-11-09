import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/models/user_model.dart';
import '../features/students/routing/student_shell.dart';
import '../features/students/screens/bookings_screen.dart';
import '../features/students/screens/course_registration_screen.dart';
import '../features/students/screens/course_details_screen.dart';
import '../features/students/screens/courses_screen.dart';
import '../features/students/screens/home_screen.dart';

import '../features/institutes/routing/institute_shell.dart';
import '../features/institutes/screens/institute_bookings_screen.dart';
import '../features/institutes/screens/institute_courses_screen.dart';
import '../features/institutes/screens/institute_students_screen.dart';
import '../features/institutes/screens/institute_dashboard_screen.dart';

import '../features/admin/routing/admin_shell.dart';
import '../features/admin/screens/admin_institutes_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_more_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

import '../features/onboarding/screens/onboarding_screen.dart';

import '../features/courses/models/course_model.dart';

import 'theme/app_theme.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = context.read<AuthController>();
    _router = GoRouter(
      initialLocation: '/onboarding',
      refreshListenable: _authController,
      redirect: _redirect,
      routes: [
        // Authentication
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

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
            final extra = state.extra;
            if (extra is! CourseModel) return const CoursesScreen();
            final course = extra;
            return CourseDetailsScreen(course: course);
          },
        ),

        // Course Registration
        GoRoute(
          path: '/course-registration',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! CourseModel) return const CoursesScreen();
            final course = extra;

            return CourseRegistrationScreen(course: course);
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

        // Student Dashboard
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

            // Bookings
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
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    if (_authController.isInitializing) {
      return location == '/onboarding' ? null : '/onboarding';
    }
    final user = _authController.currentUser;

    if ((location == '/course-details' || location == '/course-registration') &&
        state.extra is! CourseModel) {
      return '/courses_screen';
    }

    final roleHome = switch (user?.role) {
      UserRole.student => '/home_screen',
      UserRole.instituteOwner => '/institute_dashboard',
      UserRole.admin => '/admin_dashboard',
      null => null,
    };

    final isPublicRoute =
        location == '/onboarding' ||
        location == '/login' ||
        location == '/register';
    final requiredRole = switch (location) {
      '/home_screen' ||
      '/courses_screen' ||
      '/bookings_screen' ||
      '/course-details' ||
      '/course-registration' => UserRole.student,
      '/institute_dashboard' ||
      '/institute_bookings' ||
      '/institute_courses' ||
      '/institute_students' => UserRole.instituteOwner,
      '/admin_dashboard' ||
      '/admin_institutes' ||
      '/admin_users' ||
      '/admin_more' => UserRole.admin,
      _ => null,
    };

    if (user == null) {
      if (requiredRole != null) return '/login';
      return null;
    }

    if (isPublicRoute) return roleHome;
    if (requiredRole != null && user.role != requiredRole) {
      return roleHome;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,

      theme: AppTheme.light,

      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}

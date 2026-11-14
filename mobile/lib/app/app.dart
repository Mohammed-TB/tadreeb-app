import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/models/user_model.dart';
import '../features/courses/screens/student/courses_screen.dart';
import '../features/courses/screens/student/course_registration_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../features/students/routing/student_shell.dart';

import '../features/courses/screens/student/course_details_screen.dart';
import '../features/students/screens/home_screen.dart';
import '../features/students/screens/my_reservations_screen.dart';
import '../features/students/screens/reservation_details_screen.dart';
import '../features/students/models/student_reservation_model.dart';
import '../features/institutes/routing/institute_shell.dart';
import '../features/institutes/screens/add_institute_course_screen.dart';
import '../features/institutes/screens/institute_courses_screen.dart';
import '../features/institutes/screens/institute_students_screen.dart';
import '../features/institutes/screens/institute_dashboard_screen.dart';
import '../features/reservations/screens/institute_reservations_screen.dart';

import '../features/admin/routing/admin_shell.dart';
import '../features/admin/screens/admin_institutes_screen.dart';
import '../features/admin/screens/admin_add_institute_screen.dart';
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

        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),

        GoRoute(
          path: '/course-registration',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! CourseModel) {
              return const CoursesScreen();
            }
            return CourseRegistrationScreen(course: extra);
          },
        ),

        GoRoute(
          path: '/reservation-details',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! StudentReservationModel) {
              return const MyReservationsScreen();
            }
            return ReservationDetailsScreen(reservation: extra);
          },
        ),

        // Onboarding
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
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
                  path: '/institute_courses',
                  builder: (context, state) => const InstituteCoursesScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) =>
                          const AddInstituteCourseScreen(),
                    ),
                  ],
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

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/institute_reservations',
                  builder: (context, state) =>
                      const InstituteReservationsScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) =>
                          const AddInstituteCourseScreen(),
                    ),
                  ],
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
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) =>
                          const AdminAddInstituteScreen(),
                    ),
                  ],
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
            return StudentShell(
              navigationShell: navigationShell,
              showBottomNavigationBar:
                  state.uri.path != '/courses_screen/details' &&
                  state.uri.path != '/my_reservations/details',
            );
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
                  routes: [
                    GoRoute(
                      path: 'details',
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is! CourseModel) {
                          return const CoursesScreen();
                        }
                        return CourseDetailsScreen(course: extra);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // My Reservations (حجوزاتي)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my_reservations',
                  builder: (context, state) => const MyReservationsScreen(),
                  routes: [
                    GoRoute(
                      path: 'details',
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is! StudentReservationModel) {
                          return const MyReservationsScreen();
                        }
                        return ReservationDetailsScreen(reservation: extra);
                      },
                    ),
                  ],
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

    if ((location == '/courses_screen/details' ||
            location == '/course-registration') &&
        state.extra is! CourseModel) {
      return '/courses_screen';
    }

    if ((location == '/reservation-details' ||
            location == '/my_reservations/details') &&
        state.extra is! StudentReservationModel) {
      return '/my_reservations';
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
      '/courses_screen/details' ||
      '/course-registration' ||
      '/my_reservations' ||
      '/my_reservations/details' ||
      '/reservation-details' ||
      '/favorites' => UserRole.student,

      '/institute_dashboard' ||
      '/institute_courses' ||
      '/institute_students' ||
      '/institute_reservations' ||
      '/institute_courses/add' => UserRole.instituteOwner,

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

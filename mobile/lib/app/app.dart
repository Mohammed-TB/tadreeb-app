import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/models/user_model.dart';
import '../core/realtime/realtime_service.dart';
import '../features/courses/screens/student/courses_screen.dart';
import '../features/courses/screens/student/course_registration_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../features/students/routing/student_shell.dart';

import '../features/courses/screens/student/course_details_screen.dart';
import '../features/students/screens/home_screen.dart';
import '../features/students/screens/institute_details_screen.dart';
import '../features/students/screens/institutes_screen.dart';
import '../features/institutes/models/institute_model.dart';
import '../features/students/screens/my_reservations_screen.dart';
import '../features/students/screens/reservation_details_screen.dart';
import '../features/students/screens/reservation_balance_payment_screen.dart';
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
import '../features/onboarding/screens/splash_screen.dart';

import '../features/courses/models/course_model.dart';

import 'theme/app_theme.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthController _authController;
  late final RealtimeService _realtimeService;
  late final StreamSubscription<RealtimeEvent> _realtimeSubscription;
  late final GoRouter _router;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    _authController = context.read<AuthController>();
    _realtimeService = context.read<RealtimeService>();
    _authController.addListener(_syncRealtimeSession);
    _realtimeSubscription = _realtimeService.events.listen(_showRealtimeNotice);
    WidgetsBinding.instance.addObserver(this);
    _syncRealtimeSession();
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authController,
      redirect: _redirect,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

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
          path: '/institute-details',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! InstituteModel) {
              return const InstitutesScreen();
            }
            return InstituteDetailsScreen(institute: extra);
          },
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

        GoRoute(
          path: '/reservation-balance-payment',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! StudentReservationModel) {
              return const MyReservationsScreen();
            }
            return ReservationBalancePaymentScreen(reservation: extra);
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

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/institutes_screen',
                  builder: (context, state) => const InstitutesScreen(),
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

  void _syncRealtimeSession() {
    final user = _authController.currentUser;
    if (user == null) {
      if (_activeUserId != null) {
        _activeUserId = null;
        _realtimeService.disconnect();
      }
      return;
    }

    if (_activeUserId == user.id) return;
    _activeUserId = user.id;
    unawaited(_realtimeService.connect(role: user.role.name));
  }

  void _showRealtimeNotice(RealtimeEvent event) {
    final message = switch (event.name) {
      'coursePublished' => 'أصبحت دورة جديدة متاحة',
      'courseUpdated' => 'تم تحديث بيانات إحدى الدورات',
      'courseUnpublished' => 'تغيرت حالة إحدى الدورات',
      'registrationCreated' => 'وصل تسجيل جديد إلى المعهد',
      'registrationConfirmed' => 'تم تأكيد التسجيل',
      'registrationRejected' => 'تم تحديث حالة التسجيل',
      'paymentSubmitted' => 'تم إرسال سند دفع جديد للمراجعة',
      'seatHoldExpired' => 'انتهت مهلة حجز مقعد',
      _ => null,
    };
    if (message == null) return;

    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _realtimeService.onAppResumed();
    }
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    if (_authController.isInitializing &&
        location != '/splash' &&
        location != '/login' &&
        location != '/register') {
      return '/splash';
    }
    final user = _authController.currentUser;

    if ((location == '/courses_screen/details' ||
            location == '/course-registration') &&
        state.extra is! CourseModel) {
      return '/courses_screen';
    }

    if (location == '/institute-details' && state.extra is! InstituteModel) {
      return '/institutes_screen';
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

    if (location == '/splash') return null;

    final isPublicRoute =
        location == '/onboarding' ||
        location == '/login' ||
        location == '/register';
    final requiredRole = switch (location) {
      '/home_screen' ||
      '/courses_screen' ||
      '/courses_screen/details' ||
      '/course-registration' ||
      '/institutes_screen' ||
      '/institute-details' ||
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
      scaffoldMessengerKey: _scaffoldMessengerKey,

      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        ...PhoneFieldLocalization.delegates,
      ],


      theme: AppTheme.light,

      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _authController.removeListener(_syncRealtimeSession);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_realtimeSubscription.cancel());
    _router.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_1/features/courses/controllers/reservation_controller.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';

import 'core/network/api_client.dart';
import 'core/network/token_storage_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';

import 'features/courses/controllers/course_controller.dart';
import 'features/courses/services/course_service.dart';
import 'features/courses/services/reservation_service.dart' as student_res;
import 'features/favorites/controllers/favorite_controller.dart';
import 'features/favorites/services/favorite.service.dart';
import 'features/admin/controllers/admin_institute_controller.dart';
import 'features/admin/services/admin_institute_service.dart';

import 'features/institutes/controllers/institute_controller.dart';
import 'features/institutes/services/institute_service.dart';

import 'features/reservations/controllers/institute_reservation_controller.dart';
import 'features/reservations/services/reservation_service.dart' as institute_res;

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorageService>(create: (_) => TokenStorageService()),
        Provider<ApiClient>(
          create: (context) =>
              ApiClient(tokenStorage: context.read<TokenStorageService>()),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            apiClient: context.read<ApiClient>(),
            tokenStorage: context.read<TokenStorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final controller = AuthController(context.read<AuthService>());
            unawaited(controller.restoreSession());
            return controller;
          },
        ),

        // Courses
        Provider<CourseService>(
          create: (context) =>
              CourseService(apiClient: context.read<ApiClient>()),
        ),
        Provider<FavoriteService>(
          create: (context) =>
              FavoriteService(apiClient: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<FavoriteController>(
          create: (context) =>
              FavoriteController(context.read<FavoriteService>()),
        ),
        Provider<student_res.ReservationService>(
          create: (context) =>
              student_res.ReservationService(apiClient: context.read<ApiClient>()),
        ),

        ChangeNotifierProvider<CourseController>(
          create: (context) => CourseController(context.read<CourseService>()),
        ),

        // Student Reservation Controller
        ChangeNotifierProvider(
          create: (context) => ReservationController(
            context.read<student_res.ReservationService>(),
          ),
        ),

        // Institutes
        Provider<InstituteService>(
          create: (context) =>
              InstituteService(apiClient: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<InstituteController>(
          create: (context) =>
              InstituteController(context.read<InstituteService>())
                ..getInstitutes(),
        ),

        Provider<AdminInstituteService>(
          create: (context) =>
              AdminInstituteService(apiClient: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AdminInstituteController>(
          create: (context) =>
              AdminInstituteController(context.read<AdminInstituteService>()),
        ),

        // Institute Owner Reservations
        Provider<institute_res.ReservationService>(
          create: (context) =>
              institute_res.ReservationService(apiClient: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<InstituteReservationController>(
          create: (context) => InstituteReservationController(
            context.read<institute_res.ReservationService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

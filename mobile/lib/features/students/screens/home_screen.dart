
import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/features/students/widgets/header_home.dart';
import 'package:project_1/features/students/widgets/list_category.dart';
import 'package:project_1/features/students/widgets/most_popular_courses.dart';
import 'package:project_1/features/students/widgets/most_popular_institutes.dart';

import '../../courses/models/course_model.dart';
import '../models/student_model.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showDetailsCourse(CourseModel course) {
    context.push(
      '/course-details',
      extra: course,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeaderHome(),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            ListCategory(
              categories: categories,
            ),

            const SizedBox(
              height: AppSpacing.sectionGap,
            ),

            MostPopularCourses(
              showDetailsCourse: _showDetailsCourse,
            ),

            const SizedBox(
              height: AppSpacing.sectionGap,
            ),

            const MostPopularInstitutes(),

            const SizedBox(
              height: AppSpacing.xl,
            ),
          ],
        ),
      ),
    );
  }
}

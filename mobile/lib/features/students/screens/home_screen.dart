
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/features/students/widgets/header_home.dart';
import 'package:project_1/features/students/widgets/list_category.dart';
import 'package:project_1/features/students/widgets/most_popular_courses.dart';
import 'package:project_1/features/students/widgets/most_popular_institutes.dart';

import '../../../core/mock_data/categories_data.dart';
import '../../courses/models/course_model.dart';

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

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderHome(
            onMenuTap: _openDrawer,
          ),

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
    );
  }
}

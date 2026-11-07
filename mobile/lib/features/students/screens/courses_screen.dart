
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/core/widgets/search.dart';
import 'package:project_1/features/courses/controllers/course_controller.dart';
import 'package:project_1/features/students/widgets/course_card.dart';
import 'package:project_1/features/students/widgets/list_category.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/mock_data/categories_data.dart';
import '../../courses/models/course_model.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseController>().getCourses();
    });
  }

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
    final controller = context.watch<CourseController>();
    final courses = controller.courses;

    return Column(
      children: [
        // Page header
        SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            width: double.infinity,
            color: AppColors.primary,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'الدورات',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Positioned(
                  right: 4,
                  child: IconButton(
                    onPressed: _openDrawer,
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Page content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Search(
                    hinText: 'ابحث عن دورة',
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ListCategory(
                    categories: categories,
                  ),
                ),

                const SizedBox(height: 10),

                if (controller.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (courses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('لا توجد دورات متاحة حالياً'),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(
                        height: AppSpacing.cardGap,
                      ),
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        return CourseCard(
                          course: course,
                          isHorizontal: true,
                          showDetailsCourse: () =>
                              _showDetailsCourse(course),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

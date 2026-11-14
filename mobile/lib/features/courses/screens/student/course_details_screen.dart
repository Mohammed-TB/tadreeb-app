import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/widgets/course_details_description.dart';
import 'package:project_1/features/courses/widgets/course_details_header.dart';
import 'package:project_1/features/courses/widgets/course_details_image.dart';
import 'package:project_1/features/courses/widgets/course_details_lists.dart';
import 'package:project_1/features/courses/widgets/course_details_stats.dart';
import 'package:project_1/features/courses/widgets/course_enroll_button.dart';
import 'package:project_1/features/institutes/controllers/institute_controller.dart';

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key, required this.course});

  final CourseModel course;

  String _instituteName(BuildContext context) {
    final institutes = context.watch<InstituteController>().institutes;
    for (final institute in institutes) {
      if (institute.id == course.instituteId) {
        return institute.name;
      }
    }

    return 'معهد غير معروف';
  }

  @override
  Widget build(BuildContext context) {
    final isFull = course.isFull == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تفاصيل الدورة',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CourseDetailsImage(course: course),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CourseDetailsHeader(
                    course: course,
                    instituteName: _instituteName(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CourseDetailsStats(course: course),
                  const SizedBox(height: AppSpacing.xl),
                  CourseDetailsDescription(description: course.description),
                  if (course.whatWillLearn.isNotEmpty ||
                      course.features.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    CourseDetailsLists(
                      whatWillLearn: course.whatWillLearn,
                      features: course.features,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CourseEnrollButton(
        isFull: isFull,
        onPressed: () => context.push('/course-registration', extra: course),
      ),
    );
  }
}

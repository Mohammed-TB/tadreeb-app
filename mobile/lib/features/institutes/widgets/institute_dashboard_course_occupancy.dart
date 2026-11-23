import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/institute_dashboard_model.dart';
import 'institute_dashboard_shared_components.dart';

class InstituteDashboardCourseOccupancy extends StatelessWidget {
  const InstituteDashboardCourseOccupancy({super.key, required this.courses});

  final List<InstituteDashboardCourse> courses;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return InstituteDashboardPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 32,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'لا توجد دورات منشورة لعرض إشغالها',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return InstituteDashboardPanel(
      child: Column(
        children: [
          for (var index = 0; index < courses.length; index++) ...[
            _CourseOccupancyRow(course: courses[index]),
            if (index < courses.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _CourseOccupancyRow extends StatelessWidget {
  const _CourseOccupancyRow({required this.course});

  final InstituteDashboardCourse course;

  @override
  Widget build(BuildContext context) {
    final progress = course.capacity == 0
        ? 0.0
        : (course.occupied / course.capacity).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${course.occupied} / ${course.capacity}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.primaryLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

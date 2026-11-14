import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/features/courses/models/course_model.dart';

class CourseDetailsHeader extends StatelessWidget {
  const CourseDetailsHeader({
    super.key,
    required this.course,
    required this.instituteName,
  });

  final CourseModel course;
  final String instituteName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.category,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          course.title,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                instituteName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/features/courses/models/course_model.dart';

class CourseDetailsStats extends StatelessWidget {
  const CourseDetailsStats({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.payments_outlined,
                title: 'السعر',
                value: '${course.price.toStringAsFixed(0)} ريال',
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'العربون',
                value: '${course.depositAmount.toStringAsFixed(0)} ريال',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.people_outline,
                title: 'المقاعد',
                value: '${course.enrolledCount + course.reservedCount}/${course.capacity}',
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.category_outlined,
                title: 'التصنيف',
                value: course.category,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

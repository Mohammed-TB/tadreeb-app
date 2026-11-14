import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';

class CourseDetailsLists extends StatelessWidget {
  const CourseDetailsLists({
    super.key,
    required this.whatWillLearn,
    required this.features,
  });

  final List<String> whatWillLearn;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (whatWillLearn.isNotEmpty)
          _CourseListSection(
            title: 'ماذا ستتعلم؟',
            icon: Icons.school_outlined,
            items: whatWillLearn,
          ),
        if (whatWillLearn.isNotEmpty && features.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (features.isNotEmpty)
          _CourseListSection(
            title: 'مميزات الدورة',
            icon: Icons.stars_outlined,
            items: features,
          ),
      ],
    );
  }
}

class _CourseListSection extends StatelessWidget {
  const _CourseListSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

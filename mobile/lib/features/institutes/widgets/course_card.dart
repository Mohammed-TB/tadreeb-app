import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/excel.course.png',
            width: double.infinity,
            height: 132,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('دورة ${number + 1}', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'عدد الطلاب المسجلين ${20 + number}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _actionChip(
                        label: 'تعديل',
                        icon: Icons.edit_outlined,
                        color: AppColors.success,
                        background: AppColors.successLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _actionChip(
                        label: 'إغلاق',
                        icon: Icons.stop_circle_outlined,
                        color: AppColors.error,
                        background: AppColors.errorLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _actionChip(
                        label: 'نشر',
                        icon: Icons.send_outlined,
                        color: AppColors.primaryDark,
                        background: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

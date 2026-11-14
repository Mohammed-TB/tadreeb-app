import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_dashboard_stats.dart';

class AdminPlatformSummary extends StatelessWidget {
  const AdminPlatformSummary({super.key, required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('مستخدمون نشطون', stats.users.active, AppColors.success),
      ('معاهد معلقة', stats.institutes.pending, AppColors.warning),
      ('معاهد موقوفة', stats.institutes.suspended, AppColors.error),
      ('طلاب', stats.users.students, AppColors.primary),
      ('أصحاب معاهد', stats.users.instituteOwners, AppColors.primaryDark),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(items[index].$1, style: AppTypography.bodyMedium),
                ),
                Text(
                  items[index].$2.toString(),
                  style: AppTypography.titleSmall.copyWith(
                    color: items[index].$3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

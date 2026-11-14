import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_institute_model.dart';

class AdminInstituteCard extends StatelessWidget {
  const AdminInstituteCard({super.key, required this.institute});

  final AdminInstituteModel institute;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (institute.status) {
      AdminInstituteStatus.active => AppColors.success,
      AdminInstituteStatus.pending => AppColors.warning,
      AdminInstituteStatus.suspended => AppColors.error,
    };
    final statusTint = switch (institute.status) {
      AdminInstituteStatus.active => AppColors.successLight,
      AdminInstituteStatus.pending => AppColors.warningLight,
      AdminInstituteStatus.suspended => AppColors.errorLight,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.business_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institute.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'تاريخ التسجيل: '
                  '${DateFormat.yMMMd('ar').format(institute.createdAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: statusTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              institute.status.label,
              style: AppTypography.labelSmall.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

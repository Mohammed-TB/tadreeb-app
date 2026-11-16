import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../models/student_reservation_model.dart';

class StudentReservationCard extends StatelessWidget {
  const StudentReservationCard({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  final StudentReservationModel reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (
      statusColor,
      statusBackground,
      statusIcon,
    ) = switch (reservation.normalizedStatus) {
      'confirmed' => (
        AppColors.success,
        AppColors.successLight,
        Icons.check_circle_rounded,
      ),
      'paymentsubmitted' => (
        AppColors.primary,
        AppColors.primaryLight,
        Icons.hourglass_top_rounded,
      ),
      'rejected' => (
        AppColors.error,
        AppColors.errorLight,
        Icons.cancel_rounded,
      ),
      'pendingpayment' => (
        AppColors.accentDark,
        AppColors.accentLight,
        Icons.payment_rounded,
      ),
      _ => (AppColors.textSecondary, AppColors.field, Icons.history_rounded),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.instituteName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        reservation.courseTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              reservation.statusLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

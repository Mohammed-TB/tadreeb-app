import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../models/reservation_model.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  final ReservationModel reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusBackground) = switch (reservation
        .status
        .replaceAll('_', '')
        .toLowerCase()) {
      'confirmed' => ('مؤكد ومقبول', AppColors.success, AppColors.successLight),
      'rejected' => ('مرفوض', AppColors.error, AppColors.errorLight),
      'paymentsubmitted' => (
        'بانتظار المراجعة',
        AppColors.accentDark,
        AppColors.accentLight,
      ),
      'pendingpayment' => (
        'بانتظار السداد',
        AppColors.warning,
        AppColors.warningLight,
      ),
      'cancelled' => ('ملغي', AppColors.textHint, AppColors.field),
      'expired' => ('منتهي', AppColors.textHint, AppColors.field),
      _ => (reservation.status, AppColors.primary, AppColors.primaryLight),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.studentName,
                      maxLines: 1,
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
                      child: Text(
                        statusLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (reservation.balancePaymentStatus == 'pending') ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'دفعة متبقية بانتظار المراجعة',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_left_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

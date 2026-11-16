import 'package:flutter/material.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status
    });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.replaceAll('_', '').toLowerCase();
    final (label, foreground, background) = switch (normalized) {
      'confirmed' => ('مؤكد', AppColors.success, AppColors.successLight),
      'paymentsubmitted' => (
        'قيد المراجعة',
        AppColors.accentDark,
        AppColors.accentLight,
      ),
      'pendingpayment' => (
        'بانتظار الدفع',
        AppColors.warning,
        AppColors.warningLight,
      ),
      'rejected' => ('مرفوض', AppColors.error, AppColors.errorLight),
      'expired' => ('منتهي', AppColors.textHint, AppColors.field),
      'cancelled' => ('ملغي', AppColors.textHint, AppColors.field),
      _ => (status, AppColors.primary, AppColors.primaryLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/institute_dashboard_model.dart';
import 'institute_dashboard_shared_components.dart';

class InstituteDashboardReservationStatusSummary extends StatelessWidget {
  const InstituteDashboardReservationStatusSummary({
    super.key,
    required this.summary,
  });

  final InstituteDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('ar');
    final rows = [
      (
        title: 'مؤكدة',
        value: summary.confirmedThisMonth,
        color: AppColors.success,
      ),
      (
        title: 'قيد مراجعة الإيصال',
        value: summary.paymentSubmittedThisMonth,
        color: AppColors.warning,
      ),
      (
        title: 'بانتظار الدفع',
        value: summary.pendingPaymentThisMonth,
        color: AppColors.primary,
      ),
      (
        title: 'مرفوضة',
        value: summary.rejectedThisMonth,
        color: AppColors.error,
      ),
      (
        title: 'منتهية',
        value: summary.expiredThisMonth,
        color: AppColors.textSecondary,
      ),
      (
        title: 'ملغاة',
        value: summary.cancelledThisMonth,
        color: AppColors.textHint,
      ),
    ];

    return InstituteDashboardPanel(
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _ReservationStatusRow(
              title: rows[index].title,
              value: numberFormat.format(rows[index].value),
              color: rows[index].color,
            ),
            if (index < rows.length - 1) const Divider(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _ReservationStatusRow extends StatelessWidget {
  const _ReservationStatusRow({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: AppTypography.bodyMedium)),
        Text(value, style: AppTypography.titleSmall.copyWith(color: color)),
      ],
    );
  }
}

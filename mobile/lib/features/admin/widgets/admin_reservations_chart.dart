import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_dashboard_stats.dart';

class AdminReservationsChart extends StatelessWidget {
  const AdminReservationsChart({super.key, required this.reservations});

  final AdminReservationStats reservations;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('ar');
    final states = [
      _ReservationState('مؤكد', reservations.confirmed, AppColors.success),
      _ReservationState(
        'بانتظار الدفع',
        reservations.pendingPayment,
        AppColors.primary,
      ),
      _ReservationState(
        'الإيصال قيد المراجعة',
        reservations.paymentSubmitted,
        AppColors.warning,
      ),
      _ReservationState('مرفوض', reservations.rejected, AppColors.error),
      _ReservationState(
        'ملغى أو منتهي',
        reservations.closed,
        AppColors.textHint,
      ),
    ];
    final visibleStates = states.where((state) => state.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: reservations.total == 0
                ? Center(
                    child: Text(
                      'لا توجد حجوزات مسجلة',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 48,
                          sections: visibleStates
                              .map(
                                (state) => PieChartSectionData(
                                  value: state.value.toDouble(),
                                  color: state.color,
                                  radius: 25,
                                  showTitle: false,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            numberFormat.format(reservations.total),
                            style: AppTypography.titleLarge,
                          ),
                          Text(
                            'حجز',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final state in states)
            _ReservationLegendRow(
              state: state,
              formattedValue: numberFormat.format(state.value),
            ),
        ],
      ),
    );
  }
}

class _ReservationState {
  const _ReservationState(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _ReservationLegendRow extends StatelessWidget {
  const _ReservationLegendRow({
    required this.state,
    required this.formattedValue,
  });

  final _ReservationState state;
  final String formattedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: state.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(state.label, style: AppTypography.bodySmall)),
          Text(formattedValue, style: AppTypography.titleSmall),
        ],
      ),
    );
  }
}

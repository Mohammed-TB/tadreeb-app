import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/admin_dashboard_stats.dart';

class AdminRevenueChart extends StatelessWidget {
  const AdminRevenueChart({super.key, required this.revenue});

  final AdminRevenueStats revenue;

  static const _months = [
    'ينا',
    'فبر',
    'مار',
    'أبر',
    'ماي',
    'يون',
    'يول',
    'أغس',
    'سبت',
    'أكت',
    'نوف',
    'ديس',
  ];

  @override
  Widget build(BuildContext context) {
    final monthlyValues = _lastSixMonths();
    final maxValue = monthlyValues.fold<double>(
      0,
      (maximum, item) => math.max(maximum, item.revenue),
    );
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final amountFormat = NumberFormat.decimalPattern('ar');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إجمالي الإيرادات المحصلة', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${amountFormat.format(revenue.total)} ر.ي',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyValues.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            _months[monthlyValues[index].month - 1],
                            style: AppTypography.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(monthlyValues.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyValues[index].revenue,
                        width: 18,
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.primary,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AdminMonthlyRevenue> _lastSixMonths() {
    final now = DateTime.now();
    final byMonth = {
      for (final item in revenue.monthly) '${item.year}-${item.month}': item,
    };

    return List.generate(6, (index) {
      final date = DateTime(now.year, now.month - 5 + index, 1);
      return byMonth['${date.year}-${date.month}'] ??
          AdminMonthlyRevenue(
            year: date.year,
            month: date.month,
            revenue: 0,
            count: 0,
          );
    });
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );
  }
}

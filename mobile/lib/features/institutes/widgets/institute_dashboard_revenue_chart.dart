import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/institute_dashboard_model.dart';
import 'institute_dashboard_shared_components.dart';

class InstituteDashboardRevenueChart extends StatelessWidget {
  const InstituteDashboardRevenueChart({super.key, required this.summary});

  final InstituteDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final revenue = summary.monthlyRevenue;
    var maxRevenue = 0.0;
    for (final month in revenue) {
      if (month.revenue > maxRevenue) maxRevenue = month.revenue;
    }
    final chartMax = maxRevenue == 0 ? 1.0 : maxRevenue * 1.2;

    return InstituteDashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إجمالي الإيرادات', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            CurrencyFormatter.format(summary.totalRevenue),
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMax,
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
                        if (index < 0 || index >= revenue.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            _monthLabel(revenue[index].month),
                            style: AppTypography.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < revenue.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: revenue[index].revenue,
                          width: 17,
                          borderRadius: BorderRadius.circular(5),
                          color: AppColors.primary,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: chartMax,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(int month) => const [
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
  ][month - 1];
}

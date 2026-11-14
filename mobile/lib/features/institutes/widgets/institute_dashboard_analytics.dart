import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/institute_dashboard_model.dart';

class InstituteDashboardAnalytics extends StatelessWidget {
  const InstituteDashboardAnalytics({super.key, required this.data});

  final InstituteDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStats(),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle('الإيرادات والتحصيلات', 'آخر 6 أشهر'),
        const SizedBox(height: AppSpacing.sm),
        _buildRevenueChart(),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle('حالة التسجيلات', 'هذا الشهر'),
        const SizedBox(height: AppSpacing.sm),
        _buildReservations(),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle('أداء الدورات', 'الأكثر إشغالاً'),
        const SizedBox(height: AppSpacing.sm),
        _buildCourseOccupancy(),
      ],
    );
  }

  Widget _buildStats() {
    final summary = data.summary;
    final numberFormat = NumberFormat.decimalPattern('ar');
    final cards = [
      _DashboardMetric(
        title: 'الدورات',
        value: numberFormat.format(summary.totalCourses),
        subtitle: 'منشورة: ${numberFormat.format(summary.publishedCourses)}',
        icon: Icons.menu_book_outlined,
        color: AppColors.primary,
        tint: AppColors.primaryLight,
      ),
      _DashboardMetric(
        title: 'التسجيلات هذا الشهر',
        value: numberFormat.format(summary.reservationsThisMonth),
        subtitle:
            'إجمالي التسجيلات: ${numberFormat.format(summary.totalReservations)}',
        icon: Icons.people_outline_rounded,
        color: AppColors.success,
        tint: AppColors.successLight,
      ),
      _DashboardMetric(
        title: 'إيصالات بانتظار المراجعة',
        value: numberFormat.format(summary.receiptsToReview),
        subtitle: 'تحتاج إلى مراجعة',
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        tint: AppColors.warningLight,
      ),
      _DashboardMetric(
        title: 'الإيرادات المحصلة',
        value: numberFormat.format(summary.totalRevenue),
        subtitle: 'ريال يمني',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primaryDark,
        tint: AppColors.primaryLight,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.cardGap,
        mainAxisSpacing: AppSpacing.cardGap,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) => _StatCard(metric: cards[index]),
    );
  }

  Widget _buildRevenueChart() {
    final revenue = data.summary.monthlyRevenue;
    var maxRevenue = 0.0;
    for (final month in revenue) {
      if (month.revenue > maxRevenue) maxRevenue = month.revenue;
    }
    final chartMax = maxRevenue == 0 ? 1.0 : maxRevenue * 1.2;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إجمالي الإيرادات', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${NumberFormat.decimalPattern('ar').format(data.summary.totalRevenue)} ر.ي',
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

  Widget _buildReservations() {
    final reservations = data.summary;
    final numberFormat = NumberFormat.decimalPattern('ar');
    final rows = [
      (
        title: 'مؤكدة',
        value: reservations.confirmedThisMonth,
        color: AppColors.success,
      ),
      (
        title: 'قيد مراجعة الإيصال',
        value: reservations.paymentSubmittedThisMonth,
        color: AppColors.warning,
      ),
      (
        title: 'بانتظار الدفع',
        value: reservations.pendingPaymentThisMonth,
        color: AppColors.primary,
      ),
      (
        title: 'مرفوضة',
        value: reservations.rejectedThisMonth,
        color: AppColors.error,
      ),
      (
        title: 'منتهية',
        value: reservations.expiredThisMonth,
        color: AppColors.textSecondary,
      ),
      (
        title: 'ملغاة',
        value: reservations.cancelledThisMonth,
        color: AppColors.textHint,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
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

  Widget _buildCourseOccupancy() {
    final courses = data.courseOccupancy;
    if (courses.isEmpty) {
      return _EmptyDashboardCard(
        icon: Icons.menu_book_outlined,
        message: 'لا توجد دورات منشورة لعرض إشغالها',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < courses.length; index++) ...[
            _CourseOccupancyRow(course: courses[index]),
            if (index < courses.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String trailing) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.titleMedium)),
        Text(
          trailing,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );
  }
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.metric});

  final _DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: metric.tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, color: metric.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  metric.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSmall.copyWith(color: metric.color),
          ),
          Text(
            metric.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: metric.color),
          ),
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

class _CourseOccupancyRow extends StatelessWidget {
  const _CourseOccupancyRow({required this.course});

  final InstituteDashboardCourse course;

  @override
  Widget build(BuildContext context) {
    final progress = course.capacity == 0
        ? 0.0
        : (course.occupied / course.capacity).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${course.occupied} / ${course.capacity}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.primaryLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  const _EmptyDashboardCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

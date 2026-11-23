import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/institute_dashboard_model.dart';

class InstituteDashboardMetrics extends StatelessWidget {
  const InstituteDashboardMetrics({super.key, required this.summary});

  final InstituteDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
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
        title: 'التسجيلات المؤكدة هذا الشهر',
        value: numberFormat.format(summary.confirmedThisMonth),
        subtitle: 'عدد الحجوزات المعتمدة ',
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
        value: CurrencyFormatter.format(summary.totalRevenue),
        subtitle: AppCurrency.current.symbol,
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

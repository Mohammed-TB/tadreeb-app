import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../models/admin_dashboard_stats.dart';

class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key, required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('ar');
    final cards = [
      _AdminStatCardData(
        title: 'المستخدمون',
        value: stats.users.total,
        subtitle: 'جديد خلال 30 يوماً: ${stats.users.newLast30Days}',
        icon: Icons.people_outline_rounded,
        color: AppColors.primary,
        tint: AppColors.primaryLight,
      ),
      _AdminStatCardData(
        title: 'المعاهد',
        value: stats.institutes.total,
        subtitle:
            'نشط ${stats.institutes.active} • بانتظار ${stats.institutes.pending}',
        icon: Icons.business_outlined,
        color: AppColors.success,
        tint: AppColors.successLight,
      ),
      _AdminStatCardData(
        title: 'الدورات',
        value: stats.courses.total,
        subtitle: 'منشورة: ${stats.courses.published}',
        icon: Icons.menu_book_outlined,
        color: AppColors.accentDark,
        tint: AppColors.accentLight,
      ),
      _AdminStatCardData(
        title: 'الحجوزات',
        value: stats.reservations.total,
        subtitle: 'جديد خلال 30 يوماً: ${stats.reservations.newLast30Days}',
        icon: Icons.bookmark_outline_rounded,
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
        childAspectRatio: 1.48,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _AdminStatCard(
          data: card,
          formattedValue: numberFormat.format(card.value),
        );
      },
    );
  }
}

class _AdminStatCardData {
  const _AdminStatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({required this.data, required this.formattedValue});

  final _AdminStatCardData data;
  final String formattedValue;

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
                  color: data.tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 19),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          Text(
            formattedValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: data.color),
          ),
        ],
      ),
    );
  }
}

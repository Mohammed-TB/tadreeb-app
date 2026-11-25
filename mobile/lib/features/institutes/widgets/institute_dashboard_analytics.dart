import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../models/institute_dashboard_model.dart';
import 'institute_dashboard_course_occupancy.dart';
import 'institute_dashboard_metrics.dart';
import 'institute_dashboard_reservation_status.dart';
import 'institute_dashboard_revenue_chart.dart';
import 'institute_dashboard_shared_components.dart';

class InstituteDashboardAnalytics extends StatelessWidget {
  const InstituteDashboardAnalytics({super.key, required this.data});

  final InstituteDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstituteDashboardMetrics(summary: data.summary),
        const SizedBox(height: AppSpacing.sectionGap),
        const InstituteDashboardSectionTitle(
          title: 'الإيرادات والتحصيلات',
          trailing: 'آخر 6 أشهر',
        ),
        const SizedBox(height: AppSpacing.sm),
        InstituteDashboardRevenueChart(summary: data.summary),
        const SizedBox(height: AppSpacing.sectionGap),
        const InstituteDashboardSectionTitle(
          title: 'حالة التسجيلات',
          trailing: 'هذا الشهر',
        ),
        const SizedBox(height: AppSpacing.sm),
        InstituteDashboardReservationStatusSummary(summary: data.summary),
        const SizedBox(height: AppSpacing.sectionGap),
        const InstituteDashboardSectionTitle(
          title: 'أداء الدورات',
          trailing: 'الأكثر إشغالاً',
        ),
        const SizedBox(height: AppSpacing.sm),
        InstituteDashboardCourseOccupancy(courses: data.courseOccupancy),
      ],
    );
  }
}

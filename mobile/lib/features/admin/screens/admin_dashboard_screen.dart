import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/admin_dashboard_stats.dart';
import '../services/admin_dashboard_service.dart';
import '../widgets/admin_dashboard_header.dart';
import '../widgets/admin_dashboard_error.dart';
import '../widgets/admin_platform_summary.dart';
import '../widgets/admin_reservations_chart.dart';
import '../widgets/admin_revenue_chart.dart';
import '../widgets/admin_stats_grid.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<AdminDashboardStats> _fetchStats() {
    final service = AdminDashboardService(apiClient: context.read<ApiClient>());
    return service.getStats();
  }

  Future<void> _refreshStats() {
    final refreshedStats = _fetchStats();
    setState(() {
      _statsFuture = refreshedStats;
    });

    return refreshedStats.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        // FutureBuilder displays the request error in the dashboard.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName = context.watch<AuthController>().currentUser?.name;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          AdminDashboardHeader(adminName: adminName),
          Expanded(
            child: FutureBuilder<AdminDashboardStats>(
              future: _statsFuture,
              builder: (context, snapshot) => _buildDashboardBody(snapshot),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardBody(AsyncSnapshot<AdminDashboardStats> snapshot) {
    return RefreshIndicator(
      onRefresh: _refreshStats,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          if (snapshot.hasError)
            AdminDashboardError(
              message: _errorMessage(snapshot.error),
              onRetry: () {
                setState(() {
                  _statsFuture = _fetchStats();
                });
              },
            )
          else if (!snapshot.hasData)
            const SizedBox(
              height: 320,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            _buildDashboardSections(snapshot.data!),
        ],
      ),
    );
  }

  Widget _buildDashboardSections(AdminDashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminStatsGrid(stats: stats),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle('الإيرادات المحصلة', 'آخر 6 أشهر'),
        const SizedBox(height: AppSpacing.sm),
        AdminRevenueChart(revenue: stats.revenue),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle('حالة الحجوزات', 'إجمالي الحجوزات'),
        const SizedBox(height: AppSpacing.sm),
        AdminReservationsChart(reservations: stats.reservations),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle('حالة المنصة', 'ملخص الأعداد'),
        const SizedBox(height: AppSpacing.sm),
        AdminPlatformSummary(stats: stats),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.titleMedium)),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) {
      return 'استجابة إحصائيات المنصة غير صالحة';
    }
    return 'تعذر تحميل بيانات لوحة المسؤول. حاول مجدداً.';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/institute_dashboard_model.dart';
import '../services/institute_dashboard_service.dart';
import '../widgets/institute_dashboard_activity.dart';
import '../widgets/institute_dashboard_analytics.dart';

class InstituteDashboardScreen extends StatefulWidget {
  const InstituteDashboardScreen({super.key});

  @override
  State<InstituteDashboardScreen> createState() =>
      _InstituteDashboardScreenState();
}

class _InstituteDashboardScreenState extends State<InstituteDashboardScreen> {
  late Future<InstituteDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboard();
  }

  Future<InstituteDashboardData> _fetchDashboard() {
    return InstituteDashboardService(
      apiClient: context.read<ApiClient>(),
    ).getDashboard();
  }

  Future<void> _refreshDashboard() {
    final refreshedDashboard = _fetchDashboard();
    setState(() => _dashboardFuture = refreshedDashboard);
    return refreshedDashboard.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = context.watch<AuthController>().currentUser?.name;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<InstituteDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) =>
            _buildDashboard(context, snapshot, ownerName),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    AsyncSnapshot<InstituteDashboardData> snapshot,
    String? ownerName,
  ) {
    final dashboard = snapshot.data;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(ownerName, dashboard?.instituteName),
          ),
          if (snapshot.hasError)
            SliverToBoxAdapter(
              child: _buildErrorState(
                _errorMessage(snapshot.error),
                () => setState(() => _dashboardFuture = _fetchDashboard()),
              ),
            )
          else if (dashboard == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  InstituteDashboardAnalytics(data: dashboard),
                  const SizedBox(height: AppSpacing.sectionGap),
                  InstituteDashboardActivity(data: dashboard),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? ownerName, String? instituteName) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: const Icon(
                  Icons.business_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${ownerName?.trim().isNotEmpty == true ? ownerName : 'صاحب المعهد'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      instituteName ?? 'ملخص أداء معهدك اليوم',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Builder(
                builder: (headerContext) => IconButton(
                  onPressed: () => Scaffold.of(headerContext).openDrawer(),
                  tooltip: 'القائمة',
                  color: AppColors.textOnPrimary,
                  icon: const Icon(Icons.menu),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) {
      return 'استجابة لوحة المعهد من الخادم غير صالحة';
    }
    return 'تعذر تحميل بيانات لوحة المعهد. حاول مجدداً.';
  }
}

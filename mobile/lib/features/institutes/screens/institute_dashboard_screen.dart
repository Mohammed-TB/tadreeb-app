import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/institute_dashboard_controller.dart';
import '../widgets/institute_dashboard_activity.dart';
import '../widgets/institute_dashboard_analytics.dart';

class InstituteDashboardScreen extends StatefulWidget {
  const InstituteDashboardScreen({super.key});

  @override
  State<InstituteDashboardScreen> createState() =>
      _InstituteDashboardScreenState();
}

class _InstituteDashboardScreenState extends State<InstituteDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InstituteDashboardController>().fetchDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = context.watch<AuthController>().currentUser?.name;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<InstituteDashboardController>(
        builder: (context, controller, _) =>
            _buildDashboard(context, controller, ownerName),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    InstituteDashboardController controller,
    String? ownerName,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchDashboard(forceRefresh: true),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(ownerName, controller.data?.instituteName),
          ),
          if (controller.error != null)
            SliverToBoxAdapter(
              child: _buildErrorState(
                _errorMessage(controller.error),
                () => controller.fetchDashboard(forceRefresh: true),
              ),
            )
          else if (controller.data == null)
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
                  InstituteDashboardAnalytics(data: controller.data!),
                  const SizedBox(height: AppSpacing.sectionGap),
                  InstituteDashboardActivity(data: controller.data!),
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
              Builder(
                builder: (headerContext) => IconButton(
                  onPressed: () => Scaffold.of(headerContext).openDrawer(),
                  tooltip: 'القائمة الرئيسية',
                  color: AppColors.textOnPrimary,
                  icon: const Icon(Icons.menu),
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

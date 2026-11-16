import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../../core/widgets/search.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../widgets/student_reservation_card.dart';

/// شاشة حجوزاتي الخاصة بالطالب متطابقة 100% مع الـ Backend ونظام التصميم
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReservationController>().fetchMyReservations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.background,
        child: Consumer<ReservationController>(
          builder: (context, controller, _) {
            final hasActiveFilters =
                controller.searchQuery.isNotEmpty ||
                (controller.statusFilter != null &&
                    controller.statusFilter != 'ALL');

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.fetchMyReservations(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ترويسة شاشة حجوزاتي
                  SliverToBoxAdapter(child: _buildHeader()),

                  // محتوى الشاشة
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.md,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // شريط البحث الموحد Search
                        Search(
                          controller: _searchController,
                          hinText: 'ابحث باسم الدورة أو المعهد...',
                          isShowFilter: false,
                          onChanged: (val) => controller.setSearchQuery(val),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // شرائح الفلترة الذكية
                        _buildFilterChips(controller),
                        const SizedBox(height: AppSpacing.md),

                        // الحالات: تحميل / خطأ / فارغ / القائمة
                        if (controller.isLoadingReservations &&
                            controller.myReservations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xxxl,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (controller.errorMessage != null &&
                            controller.myReservations.isEmpty)
                          _buildErrorState(controller)
                        else if (controller.filteredReservations.isEmpty)
                          _buildEmptyState(hasActiveFilters, controller)
                        else
                          ...controller.filteredReservations.map(
                            (r) => StudentReservationCard(
                              reservation: r,
                              onTap: () => context.push(
                                '/reservation-details',
                                extra: r,
                              ),
                            ),
                          ),

                        const SizedBox(height: AppSpacing.xxxl),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'حجوزاتي',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PositionedDirectional(
                start: 4,
                child: Builder(
                  builder: (headerContext) => IconButton(
                    onPressed: () => Scaffold.of(headerContext).openDrawer(),
                    tooltip: 'القائمة الرئيسية',
                    color: AppColors.textOnPrimary,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ReservationController controller) {
    final filters =
        <
          ({
            String label,
            String? status,
            int count,
            IconData icon,
            Color color,
          })
        >[
          (
            label: 'الكل',
            status: null,
            count: controller.totalCount,
            icon: Icons.tune_rounded,
            color: AppColors.primary,
          ),
          (
            label: 'بانتظار السداد',
            status: 'pendingPayment',
            count: controller.pendingPaymentCount,
            icon: Icons.payments_outlined,
            color: AppColors.accentDark,
          ),
          (
            label: 'قيد المراجعة',
            status: 'paymentSubmitted',
            count: controller.underReviewCount,
            icon: Icons.hourglass_top_rounded,
            color: AppColors.primary,
          ),
          (
            label: 'مؤكد',
            status: 'confirmed',
            count: controller.confirmedCount,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          (
            label: 'مرفوض',
            status: 'rejected',
            count: controller.rejectedCount,
            icon: Icons.cancel_outlined,
            color: AppColors.error,
          ),
        ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final selectedStatus = controller.statusFilter == 'ALL'
              ? null
              : controller.statusFilter;
          final isSelected = selectedStatus == filter.status;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.setStatusFilter(filter.status),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 9, 9),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        size: 16,
                        color: isSelected ? Colors.white : filter.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        constraints: const BoxConstraints(minWidth: 22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : filter.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filter.count}',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : filter.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState(ReservationController controller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تعذر تحميل الحجوزات',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            controller.errorMessage ?? 'حدث خطأ غير متوقع',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Button(
            text: 'إعادة المحاولة',
            variant: AppButtonVariant.accent,
            icon: Icons.refresh_rounded,
            width: 160,
            height: 40,
            onTap: () => controller.fetchMyReservations(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool hasActiveFilters,
    ReservationController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.field,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasActiveFilters
                  ? Icons.search_off_rounded
                  : Icons.event_busy_rounded,
              size: 32,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasActiveFilters ? 'لا توجد نتائج مطابقة' : 'لا توجد حجوزات سابقة',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasActiveFilters
                ? 'جرّب تغيير كلمات البحث أو اختيار فلتر آخر.'
                : 'استكشف الدورات المتاحة وسجّل في برنامجك المفضل الآن!',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: AppSpacing.md),
            Button(
              text: 'إلغاء الفلترة',
              variant: AppButtonVariant.outline,
              width: 140,
              height: 38,
              onTap: () {
                _searchController.clear();
                controller.setSearchQuery('');
                controller.setStatusFilter(null);
              },
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../../core/widgets/search.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../models/student_reservation_model.dart';
import '../widgets/student_reservation_card.dart';

/// شاشة حجوزاتي الخاصة بالطالب متطابقة 100% مع الـ Backend ونظام التصميم
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<ReservationController>(
          builder: (context, controller, _) {
            final hasActiveFilters = controller.searchQuery.isNotEmpty ||
                (controller.statusFilter != null &&
                    controller.statusFilter != 'ALL');

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.fetchMyReservations(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ترويسة شاشة حجوزاتي
                  SliverToBoxAdapter(
                    child: _buildHeader(context, controller),
                  ),

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
                              isUploading: controller.isUploadingFor(r.id),
                              onTap: () => context.push(
                                '/reservation-details',
                                extra: r,
                              ),
                              onUploadReceipt: () => _handlePickAndUploadReceipt(
                                context,
                                controller,
                                r,
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

  Widget _buildHeader(
    BuildContext context,
    ReservationController controller,
  ) {
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
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
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
                      'حجوزاتي وتدريباتي',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'متابعة حالة الحجز وسندات التحويل البنكي',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.fetchMyReservations(),
                tooltip: 'تحديث الحجوزات',
                color: AppColors.textOnPrimary,
                icon: const Icon(Icons.refresh_rounded),
              ),
              Builder(
                builder: (headerContext) => IconButton(
                  onPressed: () => Scaffold.of(headerContext).openDrawer(),
                  tooltip: 'القائمة الرئيسية',
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

  Widget _buildFilterChips(ReservationController controller) {
    final filters = <(String, String?)>[
      ('الكل (${controller.totalCount})', null),
      ('بانتظار السداد (${controller.pendingPaymentCount})', 'pendingPayment'),
      ('قيد المراجعة (${controller.underReviewCount})', 'paymentSubmitted'),
      ('مؤكد ومقبول (${controller.confirmedCount})', 'confirmed'),
      ('مرفوض (${controller.rejectedCount})', 'rejected'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = controller.statusFilter == f.$2;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(f.$1),
              selected: isSelected,
              onSelected: (_) => controller.setStatusFilter(f.$2),
              selectedColor: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.2 : 1.0,
              ),
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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

  /// رفع أو إعادة رفع سند الدفع
  Future<void> _handlePickAndUploadReceipt(
    BuildContext context,
    ReservationController controller,
    StudentReservationModel reservation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // اختيار الصورة من المعرض
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final fileName = image.name;
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final success = await controller.uploadReceipt(
      reservationId: reservation.id,
      fileBytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('تم رفع سند الدفع بنجاح وهو قيد مراجعة المعهد'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل رفع السند: ${controller.errorMessage}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

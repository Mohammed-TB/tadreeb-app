import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/saudi_date.dart';
import '../../../../core/widgets/button.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/search.dart';
import '../../../../core/widgets/text_filed_form.dart';
import '../controllers/institute_reservation_controller.dart';
import '../models/reservation_model.dart';
import '../../courses/models/course_model.dart';
import '../../courses/services/course_service.dart';
import 'institute_reservation_details_screen.dart';
import '../widgets/reservation_card.dart';
import '../widgets/in_person_registration_sheet.dart';

/// شاشة إدارة حجوزات المعهد للمالك بتصميم موحد وهادئ يطابق شاشة حجوزاتي بدون تشتت
class InstituteReservationsScreen extends StatefulWidget {
  const InstituteReservationsScreen({super.key});

  @override
  State<InstituteReservationsScreen> createState() =>
      _InstituteReservationsScreenState();
}

class _InstituteReservationsScreenState
    extends State<InstituteReservationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InstituteReservationController>().fetchReservations();
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
        drawer: const AppDrawer(),
        backgroundColor: AppColors.background,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: FloatingActionButton.extended(
            heroTag: 'institute-reservations-in-person-registration',
            onPressed: _openInPersonRegistration,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('تسجيل حضوري'),
          ),
        ),
        body: Consumer<InstituteReservationController>(
          builder: (context, controller, _) {
            final hasActiveFilters =
                controller.searchQuery.isNotEmpty ||
                (controller.statusFilter != null &&
                    controller.statusFilter != 'ALL');

            return Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.xs,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxs,
                  ),
                  child: Column(
                    children: [
                      Search(
                        controller: _searchController,
                        hinText: 'ابحث باسم الطالب، هاتفه، أو الدورة...',
                        isShowFilter: false,
                        onChanged: (value) => controller.setSearchQuery(value),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _buildFilterChips(controller),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => controller.fetchReservations(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenHorizontal,
                            AppSpacing.xs,
                            AppSpacing.screenHorizontal,
                            96,
                          ),
                          sliver: _buildReservationContent(
                            controller,
                            hasActiveFilters,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReservationContent(
    InstituteReservationController controller,
    bool hasActiveFilters,
  ) {
    if (controller.isLoading && controller.reservations.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (controller.errorMessage != null && controller.reservations.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: _buildErrorState(controller)),
      );
    }

    final reservations = controller.filteredReservations;
    if (reservations.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: _buildEmptyState(hasActiveFilters, controller)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final reservation = reservations[index];
        return ReservationCard(
          reservation: reservation,
          onTap: () => _openReservationDetails(controller, reservation),
        );
      }, childCount: reservations.length),
    );
  }

  void _openReservationDetails(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => InstituteReservationDetailsScreen(
          reservation: reservation,
          onApprove: () => _handleApprove(controller, reservation),
          onReject: () => _handleReject(controller, reservation),
        ),
      ),
    );
  }

  Future<void> _openInPersonRegistration() async {
    try {
      final coursesFuture = context.read<CourseService>().getMyCourses();
      final reservationController = context
          .read<InstituteReservationController>();

      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => FutureBuilder<List<CourseModel>>(
          future: coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SafeArea(
                child: SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildRegistrationSheetMessage(
                sheetContext,
                message: 'تعذر تحميل الدورات: ${snapshot.error}',
                icon: Icons.error_outline,
              );
            }

            final courses = (snapshot.data ?? const <CourseModel>[])
                .where(
                  (course) =>
                      course.id != null &&
                      course.status == CourseStatus.published &&
                      SaudiDate.isTodayOrLater(course.endDate),
                )
                .toList();
            if (courses.isEmpty) {
              return _buildRegistrationSheetMessage(
                sheetContext,
                message: 'لا توجد دورات منشورة متاحة للتسجيل الحضوري',
                icon: Icons.event_busy_outlined,
              );
            }

            return InPersonRegistrationSheet(
              courses: courses,
              controller: reservationController,
            );
          },
        ),
      );

      if (created == true && mounted) {
        _showMessage('تم حفظ التسجيل الحضوري بنجاح');
      }
    } catch (error) {
      if (mounted) _showMessage('تعذر فتح نموذج التسجيل: $error');
    }
  }

  Widget _buildRegistrationSheetMessage(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  /// ترويسة متطابقة ونظيفة
  Widget _buildHeader() {
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
              IconButton(
                tooltip: 'القائمة الرئيسية',
                color: Colors.white,
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة حجوزات المعهد',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
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

  /// شرائح الفلترة الذكية بدون شاشات مزدحمة
  Widget _buildFilterChips(InstituteReservationController controller) {
    final filters = <(String, String?)>[
      ('الكل (${controller.totalCount})', null),
      ('بانتظار المراجعة (${controller.pendingCount})', 'paymentSubmitted'),
      ('مؤكد ومقبول (${controller.confirmedCount})', 'confirmed'),
      ('مرفوض (${controller.rejectedCount})', 'rejected'),
      ('بانتظار السداد', 'pendingPayment'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = controller.statusFilter == f.$2;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xxs),
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

  /// حالة الخطأ
  Widget _buildErrorState(InstituteReservationController controller) {
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
            onTap: () => controller.fetchReservations(),
          ),
        ],
      ),
    );
  }

  /// حالة القائمة الفارغة
  Widget _buildEmptyState(
    bool hasActiveFilters,
    InstituteReservationController controller,
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
                  : Icons.assignment_late_outlined,
              size: 32,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasActiveFilters
                ? 'لا توجد نتائج مطابقة'
                : 'لا توجد طلبات حجز حالياً',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasActiveFilters
                ? 'جرّب تغيير كلمات البحث أو اختيار فلتر آخر.'
                : 'ستظهر هنا طلبات تسجيل الطلاب فور إرسالها لمعهدك.',
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

  /// إجراء تأكيد وقبول الحجز
  Future<void> _handleApprove(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: const BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'تأكيد قبول الحجز',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من قبول وتأكيد حجز الطالب "${reservation.studentName}"؟ سيتم تأكيد المقعد مباشرة.',
            style: AppTypography.bodyMedium,
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: Button(
                    text: 'تراجع',
                    variant: AppButtonVariant.outline,
                    height: 40,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Button(
                    text: 'تأكيد القبول',
                    variant: AppButtonVariant.accent,
                    height: 40,
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final success = await controller.approveReservation(reservation.id);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('تم قبول وتأكيد الحجز بنجاح'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر قبول الحجز: ${controller.errorMessage}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// إجراء رفض الحجز مع حقل نصي مخصص
  Future<void> _handleReject(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) async {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.highlight_off_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'رفض طلب الحجز',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم رفض طلب حجز الطالب "${reservation.studentName}". يرجى كتابة سبب الرفض لتوضيحه للطالب:',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextFiledForm(
                  controller: reasonController,
                  hinText: 'سبب الرفض (مثال: عدم وضوح الإيصال البنكي)',
                  icon: Icons.edit_note_rounded,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: Button(
                    text: 'إلغاء',
                    variant: AppButtonVariant.outline,
                    height: 40,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Button(
                    text: 'تأكيد الرفض',
                    variant: AppButtonVariant.accent,
                    height: 40,
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة سبب الرفض لتوضيحه للطالب'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await controller.rejectReservation(
      reservation.id,
      reason: reason,
    );
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('تم رفض طلب الحجز'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر رفض الحجز: ${controller.errorMessage}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

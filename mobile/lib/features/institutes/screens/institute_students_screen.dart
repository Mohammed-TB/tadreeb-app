import 'package:flutter/material.dart';
import 'package:project_1/features/institutes/models/student_summary.dart';
import 'package:project_1/features/institutes/widgets/state_panel.dart';
import 'package:project_1/features/institutes/widgets/status_badge.dart';
import 'package:project_1/features/institutes/widgets/student_icon_text.dart';
import 'package:project_1/features/institutes/widgets/student_summary_card.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/search.dart';
import '../../reservations/controllers/institute_reservation_controller.dart';
import '../../reservations/models/reservation_model.dart';

class InstituteStudentsScreen extends StatefulWidget {
  const InstituteStudentsScreen({super.key});

  @override
  State<InstituteStudentsScreen> createState() =>
      _InstituteStudentsScreenState();
}

class _InstituteStudentsScreenState extends State<InstituteStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  String _searchQuery = '';

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
      child: Consumer<InstituteReservationController>(
        builder: (context, controller, _) {
          final students = _buildStudents(controller.reservations);
          final filteredStudents = _filterStudents(students);
          final hasFilters = _searchQuery.isNotEmpty || _statusFilter != null;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.fetchReservations(forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSummary(
                        studentCount: students.length,
                        registrationCount: controller.reservations.length,
                        confirmedCount: controller.reservations
                            .where(
                              (reservation) =>
                                  _isStatus(reservation.status, 'confirmed'),
                            )
                            .length,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Search(
                        controller: _searchController,
                        hinText: 'ابحث باسم الطالب أو الهاتف أو الدورة...',
                        isShowFilter: false,
                        onChanged: (value) => setState(
                          () => _searchQuery = value.trim().toLowerCase(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFilters(students),
                      const SizedBox(height: AppSpacing.md),
                      if (controller.isLoading && students.isEmpty)
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
                          students.isEmpty)
                        _buildError(controller)
                      else if (filteredStudents.isEmpty)
                        _buildEmptyState(hasFilters)
                      else
                        ...filteredStudents.map(_buildStudentCard),
                      const SizedBox(height: AppSpacing.xxxl),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الطلاب المسجلون',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'بيانات التسجيل في دورات معهدك',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildSummary({
    required int studentCount,
    required int registrationCount,
    required int confirmedCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: 'الطلاب',
            value: studentCount,
            icon: Icons.people_alt_outlined,
            color: AppColors.primary,
            background: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: SummaryCard(
            label: 'التسجيلات',
            value: registrationCount,
            icon: Icons.assignment_outlined,
            color: AppColors.accentDark,
            background: AppColors.accentLight,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: SummaryCard(
            label: 'تسجيل مؤكد',
            value: confirmedCount,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            background: AppColors.successLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(List<InstituteStudentSummary> students) {
    final filters = <(String, String?)>[
      ('الكل', null),
      ('مؤكد', 'confirmed'),
      ('قيد المراجعة', 'paymentSubmitted'),
      ('بانتظار الدفع', 'pendingPayment'),
      ('مرفوض', 'rejected'),
      ('منتهي', 'expired'),
      ('ملغي', 'cancelled'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final count = filter.$2 == null
              ? students.length
              : students
                    .where(
                      (student) => student.registrations.any(
                        (reservation) =>
                            _isStatus(reservation.status, filter.$2!),
                      ),
                    )
                    .length;
          final selected = _statusFilter == filter.$2;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: ChoiceChip(
              label: Text('${filter.$1} ($count)'),
              selected: selected,
              onSelected: (_) => setState(() => _statusFilter = filter.$2),
              selectedColor: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: AppTypography.labelSmall.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildStudentCard(InstituteStudentSummary student) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.primaryLight.withValues(alpha: 0.45),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              student.name.isEmpty ? 'ط' : student.name.characters.first,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            student.name.isEmpty ? 'طالب بدون اسم' : student.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconText(icon: Icons.phone_outlined, text: student.phone),
                if (student.email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  IconText(icon: Icons.email_outlined, text: student.email),
                ],
                const SizedBox(height: AppSpacing.xxs),
                IconText(
                  icon: Icons.school_outlined,
                  text: '${student.registrations.length} تسجيل',
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: AppSpacing.md),
            ...student.registrations.map(_buildRegistrationRow),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationRow(ReservationModel reservation) {
    final courseTitle = reservation.courseTitle?.trim();
    final title = courseTitle == null || courseTitle.isEmpty
        ? 'دورة غير محددة'
        : courseTitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              reservation.bookingType == 'inPerson'
                  ? Icons.storefront_outlined
                  : Icons.language_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${reservation.bookingType == 'inPerson' ? 'حضوري' : 'إلكتروني'}'
                  ' · المدفوع ${_formatAmount(reservation.amountPaid)}'
                  ' من ${_formatAmount(reservation.totalAmount)} ر.س',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (reservation.rejectionReason?.trim().isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      'سبب الرفض: ${reservation.rejectionReason}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          StatusBadge(status: reservation.status),
        ],
      ),
    );
  }

  Widget _buildError(InstituteReservationController controller) {
    return StatePanel(
      icon: Icons.cloud_off_outlined,
      title: 'تعذر تحميل بيانات الطلاب',
      message: controller.errorMessage ?? 'حدث خطأ أثناء جلب التسجيلات',
      action: OutlinedButton.icon(
        onPressed: () => controller.fetchReservations(forceRefresh: true),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('إعادة المحاولة'),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return StatePanel(
      icon: hasFilters ? Icons.search_off_rounded : Icons.school_outlined,
      title: hasFilters ? 'لا توجد نتائج مطابقة' : 'لا يوجد طلاب مسجلون بعد',
      message: hasFilters
          ? 'غيّر عبارة البحث أو فلتر الحالة لعرض النتائج.'
          : 'ستظهر هنا أسماء الطلاب من التسجيلات الإلكترونية والحضورية في دورات معهدك.',
      action: hasFilters
          ? TextButton(
              onPressed: () => setState(() {
                _searchQuery = '';
                _searchController.clear();
                _statusFilter = null;
              }),
              child: const Text('مسح البحث والفلاتر'),
            )
          : null,
    );
  }

  List<InstituteStudentSummary> _buildStudents(
    List<ReservationModel> reservations,
  ) {
    final sorted = [...reservations]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final grouped = <String, List<ReservationModel>>{};

    for (final reservation in sorted) {
      final normalizedPhone = reservation.studentPhone.trim().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final key = normalizedPhone.isEmpty ? reservation.id : normalizedPhone;
      grouped.putIfAbsent(key, () => []).add(reservation);
    }

    return grouped.values.map((items) {
      final latest = items.first;
      return InstituteStudentSummary(
        name: latest.studentName,
        phone: latest.studentPhone,
        email: latest.studentEmail ?? '',
        registrations: items,
      );
    }).toList()..sort(
      (a, b) => b.registrations.first.createdAt.compareTo(
        a.registrations.first.createdAt,
      ),
    );
  }

  List<InstituteStudentSummary> _filterStudents(
    List<InstituteStudentSummary> students,
  ) {
    return students.where((student) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery) ||
          student.phone.toLowerCase().contains(_searchQuery) ||
          student.registrations.any(
            (reservation) =>
                reservation.courseTitle?.toLowerCase().contains(_searchQuery) ??
                false,
          );
      final matchesStatus =
          _statusFilter == null ||
          student.registrations.any(
            (reservation) => _isStatus(reservation.status, _statusFilter!),
          );
      return matchesSearch && matchesStatus;
    }).toList();
  }

  static bool _isStatus(String value, String expected) =>
      value.replaceAll('_', '').toLowerCase() ==
      expected.replaceAll('_', '').toLowerCase();

  static String _formatAmount(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

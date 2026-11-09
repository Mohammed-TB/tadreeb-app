import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../courses/controllers/course_controller.dart';
import '../../courses/models/course_model.dart';
import '../../enrollments/controllers/enrollment_controller.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/models/payment_model.dart';
import '../controllers/institute_controller.dart';
import '../models/institute_model.dart';

class InstituteBookingsScreen extends StatefulWidget {
  const InstituteBookingsScreen({super.key});

  @override
  State<InstituteBookingsScreen> createState() =>
      _InstituteBookingsScreenState();
}

class _InstituteBookingsScreenState extends State<InstituteBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  InstituteModel? _institute;
  String? _loadError;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) return;
    _hasLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null || user.role != UserRole.instituteOwner) return;

    final instituteController = context.read<InstituteController>();
    if (instituteController.institutes.isEmpty) {
      await instituteController.getInstitutes();
    }
    if (!mounted) return;

    InstituteModel? institute;
    for (final item in instituteController.institutes) {
      if (item.ownerUserId == user.id) {
        institute = item;
        break;
      }
    }
    if (institute == null) {
      setState(() => _loadError = 'لا يوجد معهد مرتبط بهذا الحساب');
      return;
    }

    setState(() {
      _institute = institute;
      _loadError = null;
    });
    await context.read<EnrollmentController>().getInstituteEnrollments(
      institute.id,
    );
  }

  Future<void> _refresh() async {
    final institute = _institute;
    if (institute == null) {
      await _load();
      return;
    }
    await context.read<EnrollmentController>().getInstituteEnrollments(
      institute.id,
    );
  }

  Future<void> _approve(EnrollmentModel enrollment) async {
    final controller = context.read<EnrollmentController>();
    final succeeded = await controller.approvePayment(enrollment.id);
    if (!mounted) return;
    _showMessage(
      succeeded
          ? 'تم تأكيد الحجز بنجاح'
          : _friendlyError(controller.errorMessage),
      isError: !succeeded,
    );
  }

  Future<void> _reject(EnrollmentModel enrollment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectEnrollmentDialog(),
    );
    if (!mounted || reason == null) return;

    final institute = _institute;
    if (institute == null) {
      _showMessage('تعذر العثور على إعدادات المعهد', isError: true);
      return;
    }

    final controller = context.read<EnrollmentController>();
    final succeeded = await controller.rejectPayment(
      enrollmentId: enrollment.id,
      reason: reason,
      settings: institute.bookingSettings,
    );
    if (!mounted) return;
    _showMessage(
      succeeded
          ? 'تم رفض الطلب وإرسال السبب للطالب'
          : _friendlyError(controller.errorMessage),
      isError: !succeeded,
    );
  }

  String _friendlyError(String? error) {
    if (error == null || error.isEmpty) {
      return 'تعذر تنفيذ العملية، حاول مجددًا';
    }
    return error.replaceFirst('Exception: ', '');
  }

  Future<void> _showReceipt(EnrollmentModel enrollment) async {
    try {
      final payment = await context
          .read<EnrollmentController>()
          .getCurrentPayment(enrollment.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _ReceiptDialog(payment: payment),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error.toString()), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EnrollmentController>();
    final courses = context.watch<CourseController>().courses;
    final user = context.watch<AuthController>().currentUser;
    final enrollments = controller.instituteEnrollments;
    final pendingCount = enrollments
        .where((item) => item.status == EnrollmentStatus.pendingReview)
        .length;
    final confirmedCount = enrollments
        .where((item) => item.status == EnrollmentStatus.confirmed)
        .length;
    final otherCount = enrollments.length - pendingCount - confirmedCount;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.surface,
            child: Column(
              children: [
                SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      Builder(
                        builder: (headerContext) => IconButton(
                          onPressed: () =>
                              Scaffold.of(headerContext).openDrawer(),
                          icon: const Icon(Icons.menu),
                          tooltip: 'القائمة',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'طلبات الحجز',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'تحديث الطلبات',
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'الجديدة $pendingCount'),
                    Tab(text: 'المؤكدة $confirmedCount'),
                    Tab(text: 'أخرى $otherCount'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildContent(
            controller: controller,
            courses: courses,
            user: user,
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required EnrollmentController controller,
    required List<CourseModel> courses,
    required UserModel? user,
  }) {
    if (user == null || user.role != UserRole.instituteOwner) {
      return const _EmptyState(
        title: 'يلزم الدخول بحساب معهد',
        subtitle: 'سجل الدخول بحساب صاحب المعهد لعرض الطلبات.',
      );
    }
    if (_loadError != null) {
      return _EmptyState(
        title: 'تعذر تحميل بيانات المعهد',
        subtitle: _loadError!,
        onRetry: _refresh,
      );
    }
    if (_institute == null ||
        (controller.isLoading && controller.instituteEnrollments.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (controller.errorMessage != null &&
        controller.instituteEnrollments.isEmpty) {
      return _EmptyState(
        title: 'تعذر تحميل طلبات الحجز',
        subtitle: _friendlyError(controller.errorMessage),
        onRetry: _refresh,
      );
    }

    final sortedEnrollments = [...controller.instituteEnrollments]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groups = [
      sortedEnrollments
          .where((item) => item.status == EnrollmentStatus.pendingReview)
          .toList(),
      sortedEnrollments
          .where((item) => item.status == EnrollmentStatus.confirmed)
          .toList(),
      sortedEnrollments
          .where(
            (item) =>
                item.status != EnrollmentStatus.pendingReview &&
                item.status != EnrollmentStatus.confirmed,
          )
          .toList(),
    ];

    return TabBarView(
      controller: _tabs,
      children: [
        for (final group in groups)
          _EnrollmentList(
            enrollments: group,
            courses: courses,
            isLoading: controller.isLoading,
            onRefresh: _refresh,
            onApprove: _approve,
            onReject: _reject,
            onViewReceipt: _showReceipt,
          ),
      ],
    );
  }
}

class _EnrollmentList extends StatelessWidget {
  const _EnrollmentList({
    required this.enrollments,
    required this.courses,
    required this.isLoading,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
    required this.onViewReceipt,
  });

  final List<EnrollmentModel> enrollments;
  final List<CourseModel> courses;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<EnrollmentModel> onApprove;
  final ValueChanged<EnrollmentModel> onReject;
  final ValueChanged<EnrollmentModel> onViewReceipt;

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 420,
              child: _EmptyState(
                title: 'لا توجد طلبات في هذا القسم',
                subtitle: 'اسحب للأسفل لتحديث القائمة.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: enrollments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final enrollment = enrollments[index];
          CourseModel? course;
          for (final item in courses) {
            if (item.id == enrollment.courseId) {
              course = item;
              break;
            }
          }
          return _EnrollmentCard(
            enrollment: enrollment,
            courseName: course?.name ?? 'دورة غير متاحة',
            isLoading: isLoading,
            onApprove: () => onApprove(enrollment),
            onReject: () => onReject(enrollment),
            onViewReceipt: () => onViewReceipt(enrollment),
          );
        },
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    required this.enrollment,
    required this.courseName,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
    required this.onViewReceipt,
  });

  final EnrollmentModel enrollment;
  final String courseName;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final pending = enrollment.status == EnrollmentStatus.pendingReview;
    final statusColor = switch (enrollment.status) {
      EnrollmentStatus.confirmed => AppColors.success,
      EnrollmentStatus.pendingReview => AppColors.warning,
      EnrollmentStatus.rejected => AppColors.error,
      EnrollmentStatus.expired ||
      EnrollmentStatus.cancelled => AppColors.textSecondary,
    };
    final statusBackground = switch (enrollment.status) {
      EnrollmentStatus.confirmed => AppColors.successLight,
      EnrollmentStatus.pendingReview => AppColors.warningLight,
      EnrollmentStatus.rejected => AppColors.errorLight,
      EnrollmentStatus.expired || EnrollmentStatus.cancelled => AppColors.field,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      courseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(enrollment.status),
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'الطالب', value: enrollment.studentId),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    label: 'المبلغ المرسل',
                    value: '${enrollment.amountToPay.toStringAsFixed(0)} ريال',
                    emphasize: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(
                    label: 'تاريخ الطلب',
                    value: _formatDate(enrollment.createdAt),
                  ),
                  if (pending) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _DetailRow(
                      label: 'ينتهي خلال',
                      value: _formatDate(enrollment.expiresAt),
                      valueColor: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
            if (enrollment.lastRejectionReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _RejectionReason(reason: enrollment.lastRejectionReason!),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onViewReceipt,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('معاينة سند الدفع'),
            ),
            if (pending) ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: isLoading ? null : onApprove,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('قبول الطلب وتأكيد الحجز'),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onReject,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('رفض السند مع توضيح السبب'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.errorLight),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              color:
                  valueColor ??
                  (emphasize ? AppColors.primary : AppColors.textPrimary),
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RejectionReason extends StatelessWidget {
  const _RejectionReason({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'سبب الرفض: $reason',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
          height: 1.5,
        ),
      ),
    );
  }
}

class _RejectEnrollmentDialog extends StatefulWidget {
  const _RejectEnrollmentDialog();

  @override
  State<_RejectEnrollmentDialog> createState() =>
      _RejectEnrollmentDialogState();
}

class _RejectEnrollmentDialogState extends State<_RejectEnrollmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
      title: const Text('رفض سند الدفع'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reasonController,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'سبب الرفض',
            hintText: 'وضّح للطالب ما الذي يحتاج إلى تصحيح',
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'سبب الرفض مطلوب';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _reasonController.text.trim());
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('تأكيد الرفض'),
        ),
      ],
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final file = File(payment.receiptUrl);
    final exists = file.existsSync();
    return AlertDialog(
      title: const Text('سند الدفع'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المبلغ: ${payment.amount.toStringAsFixed(0)} ريال',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (exists)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('تعذر عرض الصورة المحددة.'),
                  ),
                )
              else
                const _InfoBanner(
                  text:
                      'الصورة محفوظة محليًا على جهاز الطالب فقط، '
                      'لذلك لا تتوفر معاينتها في هذه التجربة.',
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTypography.bodyMedium.copyWith(height: 1.5)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _statusLabel(EnrollmentStatus status) => switch (status) {
  EnrollmentStatus.pendingReview => 'قيد المراجعة',
  EnrollmentStatus.confirmed => 'مؤكد',
  EnrollmentStatus.rejected => 'مرفوض',
  EnrollmentStatus.expired => 'منتهي',
  EnrollmentStatus.cancelled => 'ملغي',
};

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

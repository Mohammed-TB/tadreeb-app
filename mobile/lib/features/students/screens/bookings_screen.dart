import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../courses/controllers/course_controller.dart';
import '../../courses/models/course_model.dart';
import '../../institutes/controllers/institute_controller.dart';
import '../../enrollments/controllers/enrollment_controller.dart';
import '../../enrollments/models/enrollment_model.dart';
import '../../enrollments/models/payment_model.dart';
import '../../institutes/models/institute_model.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
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

    final user = context.read<AuthController>().currentUser;

    if (user != null) {
      context.read<EnrollmentController>().getStudentEnrollments(user.id);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final user = context.read<AuthController>().currentUser;

    if (user == null) return;

    await context.read<EnrollmentController>().getStudentEnrollments(user.id);
  }

  Future<void> _resubmitPayment(
    EnrollmentModel enrollment,
    CourseModel? course,
  ) async {
    if (course == null) {
      _showMessage('تعذر العثور على الدورة المرتبطة بالحجز', isError: true);
      return;
    }

    InstituteModel? institute;
    for (final item in context.read<InstituteController>().institutes) {
      if (item.id == enrollment.instituteId) {
        institute = item;
        break;
      }
    }
    if (institute == null) {
      _showMessage('تعذر العثور على إعدادات المعهد', isError: true);
      return;
    }

    final submission = await showDialog<_ResubmissionDetails>(
      context: context,
      builder: (context) => const _ResubmissionDialog(),
    );
    if (!mounted || submission == null) return;

    final succeeded = await context
        .read<EnrollmentController>()
        .resubmitPayment(
          enrollmentId: enrollment.id,
          receiptUrl: submission.receiptPath,
          paymentType: submission.paymentType,
          settings: institute.bookingSettings,
        );
    if (!mounted) return;
    _showMessage(
      succeeded
          ? 'تم إرسال السند الجديد للمراجعة'
          : context.read<EnrollmentController>().errorMessage ??
                'تعذرت إعادة إرسال السند',
      isError: !succeeded,
    );
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

  CourseModel? _findCourse(String courseId, CourseController controller) {
    try {
      return controller.courses.firstWhere((course) => course.id == courseId);
    } catch (_) {
      return null;
    }
  }

  String _statusText(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.pendingReview:
        return 'قيد المراجعة';
      case EnrollmentStatus.confirmed:
        return 'مؤكد';
      case EnrollmentStatus.rejected:
        return 'مرفوض';
      case EnrollmentStatus.expired:
        return 'منتهي';
      case EnrollmentStatus.cancelled:
        return 'ملغي';
    }
  }

  Color _statusColor(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.pendingReview:
        return AppColors.warning;
      case EnrollmentStatus.confirmed:
        return AppColors.success;
      case EnrollmentStatus.rejected:
      case EnrollmentStatus.expired:
      case EnrollmentStatus.cancelled:
        return AppColors.error;
    }
  }

  Color _statusBackground(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.pendingReview:
        return AppColors.warningLight;
      case EnrollmentStatus.confirmed:
        return AppColors.successLight;
      case EnrollmentStatus.rejected:
      case EnrollmentStatus.expired:
      case EnrollmentStatus.cancelled:
        return AppColors.errorLight;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final controller = context.watch<EnrollmentController>();
    final courseController = context.watch<CourseController>();
    final instituteController = context.watch<InstituteController>();

    return Column(
      children: [
        _buildHeader(context, controller.studentEnrollments),
        Expanded(
          child: _buildContent(
            user: user,
            controller: controller,
            courseController: courseController,
            instituteController: instituteController,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, List<EnrollmentModel> enrollments) {
    final pending = enrollments
        .where((item) => item.status == EnrollmentStatus.pendingReview)
        .length;
    final confirmed = enrollments
        .where((item) => item.status == EnrollmentStatus.confirmed)
        .length;
    final other = enrollments.length - pending - confirmed;
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: AppColors.surface,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Builder(
                builder: (headerContext) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'حجوزاتي',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        child: IconButton(
                          onPressed: () {
                            Scaffold.of(headerContext).openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        child: IconButton(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'تحديث الحجوزات',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'قيد المراجعة $pending'),
                Tab(text: 'المؤكدة $confirmed'),
                Tab(text: 'أخرى $other'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required dynamic user,
    required EnrollmentController controller,
    required CourseController courseController,
    required InstituteController instituteController,
  }) {
    if (user == null) {
      return _buildMessage(
        icon: Icons.person_outline,
        title: 'يرجى تسجيل الدخول',
        subtitle: 'سجل الدخول لمتابعة حجوزاتك',
      );
    }

    if (controller.isLoading && controller.studentEnrollments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null &&
        controller.studentEnrollments.isEmpty) {
      return _buildMessage(
        icon: Icons.error_outline,
        title: 'تعذر تحميل الحجوزات',
        subtitle: controller.errorMessage!,
        action: _refresh,
      );
    }

    final allEnrollments = controller.studentEnrollments;
    final sortedEnrollments = [...allEnrollments]
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
          _buildEnrollmentList(
            group,
            allEnrollments,
            courseController,
            instituteController,
          ),
      ],
    );
  }

  Widget _buildEnrollmentList(
    List<EnrollmentModel> enrollments,
    List<EnrollmentModel> allEnrollments,
    CourseController courseController,
    InstituteController instituteController,
  ) {
    if (enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildMessage(
                icon: Icons.event_note_outlined,
                title: 'لا توجد حجوزات في هذا القسم',
                subtitle: 'ستظهر هنا الحجوزات عند تغيّر حالتها.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSummary(allEnrollments),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'الحجوزات (${enrollments.length})',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...enrollments.map((enrollment) {
            final course = _findCourse(enrollment.courseId, courseController);
            String instituteName = 'معهد غير معروف';
            for (final institute in instituteController.institutes) {
              if (institute.id == enrollment.instituteId) {
                instituteName = institute.name;
                break;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildBookingCard(
                enrollment: enrollment,
                course: course,
                instituteName: instituteName,
                onResubmit: () => _resubmitPayment(enrollment, course),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummary(List<EnrollmentModel> enrollments) {
    final pending = enrollments
        .where((item) => item.status == EnrollmentStatus.pendingReview)
        .length;

    final confirmed = enrollments
        .where((item) => item.status == EnrollmentStatus.confirmed)
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryItem(
            title: 'الإجمالي',
            count: enrollments.length,
            icon: Icons.receipt_long_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _summaryItem(
            title: 'قيد المراجعة',
            count: pending,
            icon: Icons.hourglass_empty,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _summaryItem(
            title: 'مؤكدة',
            count: confirmed,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _summaryItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: AppSpacing.xs),
          Text(
            count.toString(),
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required EnrollmentModel enrollment,
    required CourseModel? course,
    required String instituteName,
    required VoidCallback onResubmit,
  }) {
    final isPending = enrollment.status == EnrollmentStatus.pendingReview;
    final isRejected = enrollment.status == EnrollmentStatus.rejected;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course?.name ?? 'دورة غير متاحة',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      instituteName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildStatusBadge(enrollment.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          _detailRow(
            'قيمة الدورة',
            '${enrollment.coursePrice.toStringAsFixed(0)} ريال',
          ),
          const SizedBox(height: AppSpacing.sm),
          _detailRow(
            'المبلغ المدفوع',
            '${enrollment.paidAmount.toStringAsFixed(0)} ريال',
          ),
          const SizedBox(height: AppSpacing.sm),
          _detailRow(
            'المبلغ المتبقي',
            '${enrollment.remainingAmount.toStringAsFixed(0)} ريال',
          ),
          const SizedBox(height: AppSpacing.sm),
          _detailRow('تاريخ الطلب', _formatDate(enrollment.createdAt)),
          if (isPending || isRejected) ...[
            const SizedBox(height: AppSpacing.sm),
            _detailRow(
              isPending ? 'آخر موعد للمراجعة' : 'آخر موعد لإعادة الإرسال',
              '${_formatDate(enrollment.expiresAt)} - ${_formatTime(enrollment.expiresAt)}',
              valueColor: AppColors.warning,
            ),
          ],
          if (isRejected && enrollment.lastRejectionReason != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'سبب الرفض: ${enrollment.lastRejectionReason}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'رقم الحجز: ${enrollment.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoMessage(
              'تم استلام طلبك، وهو بانتظار مراجعة المعهد.',
              AppColors.warningLight,
              AppColors.warning,
            ),
          ],
          if (isRejected && enrollment.expiresAt.isAfter(DateTime.now())) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoMessage(
              'يمكنك إعادة إرسال سند الدفع قبل انتهاء المهلة.',
              AppColors.errorLight,
              AppColors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onResubmit,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('إعادة إرسال سند الدفع'),
              ),
            ),
          ],
          if (enrollment.status == EnrollmentStatus.confirmed) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoMessage(
              'تمت الموافقة على طلبك وتأكيد تسجيلك في الدورة.',
              AppColors.successLight,
              AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EnrollmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: AppTypography.labelSmall.copyWith(
          color: _statusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
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
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoMessage(String message, Color background, Color foreground) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: foreground, height: 1.5),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
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
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: action,
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

class _ResubmissionDetails {
  const _ResubmissionDetails({
    required this.paymentType,
    required this.receiptPath,
  });

  final PaymentType paymentType;
  final String receiptPath;
}

class _ResubmissionDialog extends StatefulWidget {
  const _ResubmissionDialog();

  @override
  State<_ResubmissionDialog> createState() => _ResubmissionDialogState();
}

class _ResubmissionDialogState extends State<_ResubmissionDialog> {
  final ImagePicker _picker = ImagePicker();
  PaymentType _paymentType = PaymentType.deposit;
  XFile? _receipt;
  String? _errorMessage;

  Future<void> _pickReceipt() async {
    try {
      final receipt = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (!mounted || receipt == null) return;
      setState(() {
        _receipt = receipt;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر اختيار الصورة، حاول مرة أخرى';
      });
    }
  }

  void _submit() {
    final receipt = _receipt;
    if (receipt == null) {
      setState(() => _errorMessage = 'يرجى إرفاق صورة سند التحويل');
      return;
    }

    Navigator.pop(
      context,
      _ResubmissionDetails(
        paymentType: _paymentType,
        receiptPath: receipt.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة إرسال سند الدفع'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<PaymentType>(
              initialValue: _paymentType,
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: const [
                DropdownMenuItem(
                  value: PaymentType.deposit,
                  child: Text('العربون'),
                ),
                DropdownMenuItem(
                  value: PaymentType.full,
                  child: Text('المبلغ المتبقي كاملاً'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _paymentType = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _pickReceipt,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                _receipt == null ? 'اختيار صورة السند' : 'تغيير صورة السند',
              ),
            ),
            if (_receipt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Image.file(
                File(_receipt!.path),
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Text('تم اختيار الملف لكن تعذر عرض معاينته.'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}

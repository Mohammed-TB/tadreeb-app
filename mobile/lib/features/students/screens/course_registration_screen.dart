import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

import '../../courses/models/course_model.dart';

import '../../institutes/controllers/institute_controller.dart';
import '../../institutes/models/institute_model.dart';

import '../../enrollments/controllers/enrollment_controller.dart';
import '../../enrollments/models/payment_model.dart';

class CourseRegistrationScreen extends StatefulWidget {
  const CourseRegistrationScreen({super.key, required this.course});

  final CourseModel course;

  @override
  State<CourseRegistrationScreen> createState() =>
      _CourseRegistrationScreenState();
}

class _CourseRegistrationScreenState extends State<CourseRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final TabController _tabs;

  PaymentType _paymentType = PaymentType.deposit;
  XFile? _receipt;

  bool _isSubmitting = false;
  int _currentStep = 0;

  CourseModel get course => widget.course;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabs.indexIsChanging || _tabs.index == _currentStep) return;
    setState(() => _currentStep = _tabs.index);
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  InstituteModel? get institute {
    final institutes = context.read<InstituteController>().institutes;

    try {
      return institutes.firstWhere((item) => item.id == course.instituteID);
    } catch (_) {
      return null;
    }
  }

  double get amountToPay {
    return PaymentCalculator.calculateAmount(
      course: course,
      paymentType: _paymentType,
    );
  }

  double get remainingAfterPayment {
    return course.price - amountToPay;
  }

  Future<void> _pickReceipt() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (!mounted || image == null) return;

      setState(() {
        _receipt = image;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage('تعذر اختيار الصورة، حاول مرة أخرى');
    }
  }

  void _removeReceipt() {
    setState(() {
      _receipt = null;
    });
  }

  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;

    final authController = context.read<AuthController>();
    final enrollmentController = context.read<EnrollmentController>();

    final user = authController.currentUser;

    if (user == null || user.role != UserRole.student) {
      _showMessage('يرجى تسجيل الدخول بحساب طالب أولاً');
      return;
    }

    var selectedInstitute = institute;
    if (selectedInstitute == null) {
      await context.read<InstituteController>().getInstitutes();
      if (!mounted) return;
      selectedInstitute = institute;
    }

    if (selectedInstitute == null) {
      _showMessage('تعذر العثور على المعهد المرتبط بهذه الدورة');
      return;
    }

    if (course.isFull) {
      _showMessage('عذراً، لا توجد مقاعد متاحة في هذه الدورة');
      return;
    }

    if (_receipt == null) {
      _showMessage('يرجى إرفاق صورة سند التحويل');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await enrollmentController.createEnrollment(
      studentId: user.id,
      course: course,
      paymentType: _paymentType,
      receiptUrl: _receipt!.path,
      settings: selectedInstitute.bookingSettings,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      _showMessage('تم إرسال طلب التسجيل بنجاح');

      context.go('/bookings_screen');
    } else {
      _showMessage(
        enrollmentController.errorMessage ?? 'تعذر إرسال طلب التسجيل',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تأكيد التسجيل',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined), text: 'الدورة والطالب'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'طريقة الدفع'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'السند'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildStep(
            children: [
              _buildStepIntro(
                number: '١',
                title: 'راجع بيانات التسجيل',
                subtitle: 'تأكد من الدورة وبيانات حسابك قبل المتابعة.',
              ),
              _buildCourseCard(),
              _buildStudentCard(user),
            ],
          ),
          _buildStep(
            children: [
              _buildStepIntro(
                number: '٢',
                title: 'اختر طريقة الدفع',
                subtitle: 'حدد المبلغ الذي ستسدده الآن.',
              ),
              _buildPaymentOptions(),
              _buildPaymentSummary(),
              const _LocalDemoNotice(
                text:
                    'الدفع هنا تجريبي؛ لن يتم خصم أي مبلغ. أرفق صورة السند '
                    'ليتمكن المعهد من مراجعة الطلب محليًا.',
              ),
            ],
          ),
          _buildStep(
            children: [
              _buildStepIntro(
                number: '٣',
                title: 'أرفق سند التحويل',
                subtitle:
                    'اختر صورة واضحة. ستكون متاحة على هذا الجهاز فقط في '
                    'النسخة التجريبية.',
              ),
              _buildReceiptPicker(),
              _buildPaymentSummary(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildStepActions(),
    );
  }

  Widget _buildStep({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            children[index],
          ],
        ],
      ),
    );
  }

  Widget _buildStepIntro({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              number,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepActions() {
    final isLastStep = _currentStep == _tabs.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _tabs.animateTo(_currentStep - 1),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('السابق'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : isLastStep
                    ? _submitRegistration
                    : () => _tabs.animateTo(_currentStep + 1),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isLastStep ? Icons.send_outlined : Icons.arrow_forward,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'جارٍ الإرسال'
                      : isLastStep
                      ? 'إرسال طلب التسجيل'
                      : 'متابعة',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard() {
    final selectedInstitute = institute;

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
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      selectedInstitute?.name ?? 'معهد غير معروف',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          _infoRow('التصنيف', course.category),
          const SizedBox(height: AppSpacing.sm),
          _infoRow('السعر الإجمالي', '${course.price.toStringAsFixed(0)} ريال'),
          const SizedBox(height: AppSpacing.sm),
          _infoRow('نسبة العربون', '${course.depositPercentage}%'),
        ],
      ),
    );
  }

  Widget _buildStudentCard(UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow('اسم الطالب', user?.name ?? 'غير متوفر'),
          const SizedBox(height: AppSpacing.md),
          _infoRow('البريد الإلكتروني', user?.email ?? 'غير متوفر'),
          const SizedBox(height: AppSpacing.md),
          _infoRow('رقم الهاتف', user?.phone ?? 'غير متوفر'),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _paymentOption(
          type: PaymentType.deposit,
          title: 'دفع العربون',
          subtitle: 'ادفع ${course.depositPercentage}% من قيمة الدورة الآن',
          amount: course.depositAmount,
        ),
        const SizedBox(height: AppSpacing.sm),
        _paymentOption(
          type: PaymentType.full,
          title: 'دفع المبلغ كاملاً',
          subtitle: 'سداد كامل رسوم الدورة',
          amount: course.price,
        ),
      ],
    );
  }

  Widget _paymentOption({
    required PaymentType type,
    required String title,
    required String subtitle,
    required double amount,
  }) {
    final selected = _paymentType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _paymentType = type;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${amount.toStringAsFixed(0)} ريال',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow(
            'المبلغ المطلوب الآن',
            '${amountToPay.toStringAsFixed(0)} ريال',
            valueColor: AppColors.primary,
          ),
          const Divider(height: AppSpacing.lg),
          _infoRow(
            'المبلغ المتبقي بعد الدفع',
            '${remainingAfterPayment.toStringAsFixed(0)} ريال',
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPicker() {
    if (_receipt == null) {
      return InkWell(
        onTap: _pickReceipt,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'اضغط لاختيار صورة السند',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'PNG أو JPG',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_receipt!.path),
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  alignment: Alignment.center,
                  color: AppColors.field,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                    size: 35,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'تم اختيار صورة السند',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _removeReceipt,
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalDemoNotice extends StatelessWidget {
  const _LocalDemoNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:project_1/core/widgets/button.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/core/state/app_data_change_bus.dart';
import 'package:project_1/core/widgets/app_phone_field.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/services/reservation_service.dart';
import 'package:project_1/features/courses/widgets/course_registration_components.dart';

enum _PaymentOption { deposit, full }

class CourseRegistrationScreen extends StatefulWidget {
  const CourseRegistrationScreen({super.key, required this.course});

  final CourseModel course;

  @override
  State<CourseRegistrationScreen> createState() =>
      _CourseRegistrationScreenState();
}

class _CourseRegistrationScreenState extends State<CourseRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _studentFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  late final PhoneController _phoneController;
  String? _studentPhoneE164;
  late final TabController _tabController;
  late _PaymentOption _paymentOption;
  int _currentStep = 0;
  Uint8List? _receiptBytes;
  String? _receiptName;
  String? _receiptContentType;
  String? _reservationId;
  bool _isPickingReceipt = false;
  bool _isSubmitting = false;

  static const _steps = ['البيانات', 'الدفع', 'السند'];

  CourseModel get course => widget.course;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nameController.text = user?.name ?? '';
    _phoneController = AppPhoneField.createController(
      initialValue: user?.phone,
    );
    _studentPhoneE164 = AppPhoneField.toE164(_phoneController.value);
    _paymentOption = course.depositAmount > 0
        ? _PaymentOption.deposit
        : _PaymentOption.full;
    _tabController = TabController(length: _steps.length, vsync: this)
      ..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted && _currentStep != _tabController.index) {
      setState(() => _currentStep = _tabController.index);
    }
  }

  Future<void> _continue() async {
    if (_currentStep == 0 && !_isStudentDetailsValid()) {
      _studentFormKey.currentState?.validate();
      return;
    }

    if (_currentStep < _steps.length - 1) {
      _tabController.animateTo(_currentStep + 1);
      return;
    }

    await _submitRegistration();
  }

  Future<void> _submitRegistration() async {
    if (!_isStudentDetailsValid()) {
      _tabController.animateTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _studentFormKey.currentState?.validate();
      });
      return;
    }
    final studentPhone = _studentPhoneE164;
    if (studentPhone == null) {
      _tabController.animateTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _studentFormKey.currentState?.validate();
      });
      return;
    }

    if (_receiptBytes == null ||
        _receiptName == null ||
        _receiptContentType == null) {
      _showMessage('أرفق صورة سند الدفع للمتابعة');
      return;
    }

    final courseId = course.id;
    if (courseId == null || courseId.isEmpty) {
      _showMessage('تعذر بدء التسجيل لهذه الدورة، حاول تحديث الصفحة');
      return;
    }

    setState(() => _isSubmitting = true);
    final dataChangeBus = context.read<AppDataChangeBus>();
    try {
      final service = context.read<ReservationService>();
      if (_reservationId == null) {
        _reservationId = await service.createOnlineReservation(
          courseId: courseId,
          studentName: _nameController.text.trim(),
          studentPhone: studentPhone,
          paymentOption: _paymentOption.name,
        );
        dataChangeBus.notifyChanged(
          AppDataDomain.reservations,
          AppDataChangeOrigin.courseRegistration,
          audience: AppDataAudience.student,
        );
      }

      await service.uploadReceipt(
        reservationId: _reservationId!,
        fileBytes: _receiptBytes!,
        fileName: _receiptName!,
        contentType: _receiptContentType!,
      );
      dataChangeBus.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.courseRegistration,
        audience: AppDataAudience.student,
      );

      if (!mounted) return;
      await _showSuccessDialog();
      if (mounted) context.pop();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Exception catch (error) {
      if (mounted) _showMessage('تعذر إكمال التسجيل: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickReceipt() async {
    setState(() => _isPickingReceipt = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;

      final extension = image.name.split('.').last.toLowerCase();
      const contentTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      };
      final contentType = contentTypes[extension];
      if (contentType == null) {
        _showMessage('اختر صورة بصيغة JPG أو PNG أو WEBP');
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('حجم الصورة يجب ألا يتجاوز 5 ميجابايت');
        return;
      }

      setState(() {
        _receiptBytes = bytes;
        _receiptName = image.name;
        _receiptContentType = contentType;
      });
    } on Exception catch (error) {
      if (mounted) _showMessage('تعذر اختيار الصورة: $error');
    } finally {
      if (mounted) setState(() => _isPickingReceipt = false);
    }
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 52,
        ),
        title: const Text('تم إرسال التسجيل'),
        content: const Text(
          'وصل طلبك وسند الدفع إلى المعهد، وستصلك النتيجة بعد مراجعة السند.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('العودة إلى الدورة'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isStudentDetailsValid() {
    return _validateStudentName(_nameController.text) == null &&
        _studentPhoneE164 != null;
  }

  String? _validateStudentName(String? value) {
    final nameParts = (value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return nameParts.length < 4 ? 'أدخل الاسم الرباعي كاملًا' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('التسجيل في الدورة')),
      body: Column(
        children: [
          CourseRegistrationCourseSummary(course: course),
          CourseRegistrationStepHeader(
            steps: _steps,
            currentStep: _currentStep,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStudentStep(),
                    _buildPaymentStep(),
                    _buildReceiptStep(),
                  ],
                ),
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildStudentStep() {
    return Form(
      key: _studentFormKey,

      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),

        children: [
          const CourseRegistrationStepIntro(
            title: 'بيانات الطالب',
            description: 'تأكد من كتابة بيانات التواصل بشكل صحيح.',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          CourseRegistrationTextField(
            controller: _nameController,
            label: 'الاسم الرباعي',
            hint: 'اكتب الاسم الأول واسم الأب والجد والعائلة',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: _validateStudentName,
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: AppSpacing.md),
          AppPhoneField(
            controller: _phoneController,
            labelText: 'رقم الجوال',
            hintText: 'أدخل رقم جوالك',
            textInputAction: TextInputAction.done,
            enabled: !_isSubmitting,
            onChanged: (value) => _studentPhoneE164 = value,
          ),
          const SizedBox(height: AppSpacing.md),
          const CourseRegistrationInfoBanner(
            icon: Icons.lock_outline,
            message: 'تُستخدم بياناتك للتواصل بشأن تسجيلك في هذه الدورة فقط.',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const CourseRegistrationStepIntro(
          title: 'اختر طريقة الدفع',
          description: 'يمكنك دفع العربون لحجز مقعدك أو دفع الرسوم كاملة.',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (course.depositAmount > 0) ...[
          CourseRegistrationPaymentOptionCard(
            title: 'دفع العربون',
            description: 'ادفع العربون الآن وأكمل المبلغ لاحقًا.',
            amount: course.depositAmount,
            icon: Icons.account_balance_wallet_outlined,
            isSelected: _paymentOption == _PaymentOption.deposit,
            onTap: () =>
                setState(() => _paymentOption = _PaymentOption.deposit),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        CourseRegistrationPaymentOptionCard(
          title: 'دفع المبلغ كاملًا',
          description: 'سدد رسوم الدورة كاملة من الآن.',
          amount: course.price,
          icon: Icons.payments_outlined,
          isSelected: _paymentOption == _PaymentOption.full,
          onTap: () => setState(() => _paymentOption = _PaymentOption.full),
        ),
        const SizedBox(height: AppSpacing.md),
        const CourseRegistrationInfoBanner(
          icon: Icons.verified_user_outlined,
          message: 'لن يتم تأكيد التسجيل إلا بعد مراجعة سند الدفع من المعهد.',
        ),
      ],
    );
  }

  Widget _buildReceiptStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const CourseRegistrationStepIntro(
          title: 'أرفق سند الدفع',
          description: 'ارفع صورة واضحة لإيصال التحويل بالمبلغ المحدد.',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('صورة سند الدفع', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isPickingReceipt || _isSubmitting ? null : _pickReceipt,
            child: Container(
              constraints: const BoxConstraints(minHeight: 180),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _receiptBytes == null
                      ? AppColors.border
                      : AppColors.primary,
                ),
              ),
              child: _receiptBytes == null
                  ? _receiptPlaceholder()
                  : _receiptPreview(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const CourseRegistrationInfoBanner(
          icon: Icons.info_outline,
          message:
              'الصيغ المدعومة JPG وPNG وWEBP، والحد الأقصى لحجم الصورة 5 ميجابايت.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المبلغ المطلوب', style: AppTypography.labelMedium),
              Text(
                '${_selectedAmount.toStringAsFixed(0)} ريال',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _receiptPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isPickingReceipt)
            const CircularProgressIndicator()
          else
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isPickingReceipt ? 'جارٍ فتح الصور...' : 'اختر صورة سند الدفع',
            style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'اختر صورة من معرض الصور',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptPreview() {
    return Column(
      children: [
        Image.memory(
          _receiptBytes!,
          height: 190,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _receiptName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                        _receiptBytes = null;
                        _receiptName = null;
                        _receiptContentType = null;
                      }),
                child: const Text('إزالة'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double get _selectedAmount => _paymentOption == _PaymentOption.deposit
      ? course.depositAmount
      : course.price;

  Widget _buildActions() {
    final isLastStep = _currentStep == _steps.length - 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Button(
                  isDisabled: _isSubmitting,
                  variant: AppButtonVariant.outline,
                  onTap: _isSubmitting
                      ? null
                      : () => _tabController.animateTo(_currentStep - 1),
                  text: 'السابق',
                  width: 104,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],

              Expanded(
                child: _isSubmitting
                    ? Center(child: Button(text: 'جاري الإرسال...'))
                    : Button(
                        onTap: _continue,
                        text: isLastStep ? 'إرسال التسجيل' : 'التالي',
                        icon: isLastStep
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/services/reservation_service.dart';

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
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  late final TabController _tabController;
  late _PaymentOption _paymentOption;
  int _currentStep = 0;
  Uint8List? _receiptBytes;
  String? _receiptName;
  String? _receiptContentType;
  String? _reservationId;
  bool _isPickingReceipt = false;
  bool _isSubmitting = false;

  static const _steps = ['بيانات الطالب', 'طريقة الدفع', 'سند الدفع'];

  CourseModel get course => widget.course;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
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
    try {
      final service = context.read<ReservationService>();
      _reservationId ??= await service.createOnlineReservation(
        courseId: courseId,
        studentName: _nameController.text.trim(),
        studentPhone: _phoneController.text.trim(),
        paymentOption: _paymentOption.name,
      );

      await service.uploadReceipt(
        reservationId: _reservationId!,
        fileBytes: _receiptBytes!,
        fileName: _receiptName!,
        contentType: _receiptContentType!,
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
        _validateStudentPhone(_phoneController.text) == null;
  }

  String? _validateStudentName(String? value) {
    final nameParts = (value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return nameParts.length < 4 ? 'أدخل الاسم الرباعي كاملًا' : null;
  }

  String? _validateStudentPhone(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[\s()-]'), '');
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)
        ? null
        : 'أدخل رقم جوال صحيحًا';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'إكمال التسجيل',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          _buildCourseSummary(),
          _buildStepHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentStep(),
                _buildPaymentStep(),
                _buildReceiptStep(),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildCourseSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  course.category,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${course.price.toStringAsFixed(0)} ريال',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الخطوة ${_currentStep + 1} من ${_steps.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  _steps[_currentStep],
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                minHeight: 4,
                backgroundColor: AppColors.textOnPrimary.withValues(
                  alpha: 0.25,
                ),
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.textOnPrimary,
            indicatorWeight: 3,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textOnPrimary.withValues(
              alpha: 0.7,
            ),
            labelStyle: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'البيانات'),
              Tab(text: 'الدفع'),
              Tab(text: 'السند'),
            ],
          ),
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
          _stepIntro(
            title: 'بيانات الطالب',
            description: 'تأكد من كتابة بيانات التواصل بشكل صحيح.',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الرباعي',
            hint: 'اكتب الاسم الأول واسم الأب والجد والعائلة',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: _validateStudentName,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الجوال',
            hint: '05xxxxxxxx',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: _validateStudentPhone,
          ),
          const SizedBox(height: AppSpacing.md),
          _infoBanner(
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
        _stepIntro(
          title: 'اختر طريقة الدفع',
          description: 'يمكنك دفع العربون لحجز مقعدك أو دفع الرسوم كاملة.',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        _paymentOptionCard(
          option: _PaymentOption.deposit,
          title: 'دفع العربون',
          description: 'ادفع العربون الآن وأكمل المبلغ لاحقًا.',
          amount: course.depositAmount,
          icon: Icons.account_balance_wallet_outlined,
          isEnabled: course.depositAmount > 0,
        ),
        const SizedBox(height: AppSpacing.sm),
        _paymentOptionCard(
          option: _PaymentOption.full,
          title: 'دفع المبلغ كاملًا',
          description: 'سدد رسوم الدورة كاملة من الآن.',
          amount: course.price,
          icon: Icons.payments_outlined,
          isEnabled: true,
        ),
        const SizedBox(height: AppSpacing.md),
        _infoBanner(
          icon: Icons.verified_user_outlined,
          message: 'لن يتم تأكيد التسجيل إلا بعد مراجعة سند الدفع من المعهد.',
        ),
      ],
    );
  }

  Widget _paymentOptionCard({
    required _PaymentOption option,
    required String title,
    required String description,
    required double amount,
    required IconData icon,
    required bool isEnabled,
  }) {
    final isSelected = _paymentOption == option;
    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? () => setState(() => _paymentOption = option)
              : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
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
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _stepIntro(
          title: 'أرفق سند الدفع',
          description: 'ارفع صورة واضحة لإيصال التحويل بالمبلغ المحدد.',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('صورة السند', style: AppTypography.labelLarge),
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
        _infoBanner(
          icon: Icons.info_outline,
          message:
              'الصيغ المدعومة JPG وPNG وWEBP، والحد الأقصى لحجم الصورة 5 ميجابايت.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'المبلغ المطلوب: ${_selectedAmount.toStringAsFixed(0)} ريال',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
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
            const Icon(
              Icons.cloud_upload_outlined,
              size: 44,
              color: AppColors.primary,
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isPickingReceipt ? 'جارٍ فتح الصور...' : 'اضغط لاختيار صورة السند',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textDirection: TextDirection.rtl,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _stepIntro({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
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
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBanner({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
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

  Widget _buildActions() {
    final isLastStep = _currentStep == _steps.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _tabController.animateTo(_currentStep - 1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(54, 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: const Text('السابق'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _continue,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : Text(
                          isLastStep ? 'إرسال التسجيل' : 'التالي',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

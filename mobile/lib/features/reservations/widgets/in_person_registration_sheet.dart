import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_phone_field.dart';
import '../../courses/models/course_model.dart';
import '../controllers/institute_reservation_controller.dart';

class InPersonRegistrationSheet extends StatefulWidget {
  const InPersonRegistrationSheet({
    required this.courses,
    required this.controller,
    super.key,
  });

  final List<CourseModel> courses;
  final InstituteReservationController controller;

  @override
  State<InPersonRegistrationSheet> createState() =>
      _InPersonRegistrationSheetState();
}

class _InPersonRegistrationSheetState extends State<InPersonRegistrationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = AppPhoneField.createController();
  late String _courseId;
  String _paymentOption = 'full';
  bool _isSubmitting = false;
  bool _isLookingUpStudent = false;
  bool _lookupFailed = false;
  String? _lookupMessage;
  String? _autoFilledName;
  Timer? _studentLookupDebounce;
  int _studentLookupRequest = 0;

  CourseModel get _selectedCourse =>
      widget.courses.firstWhere((course) => course.id == _courseId);

  double get _selectedAmount => _paymentOption == 'deposit'
      ? _selectedCourse.depositAmount
      : _selectedCourse.price;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courses.first.id!;
  }

  @override
  void dispose() {
    _studentLookupDebounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onStudentPhoneChanged(String? phone) {
    _studentLookupDebounce?.cancel();
    final requestId = ++_studentLookupRequest;

    if (_autoFilledName != null && _nameController.text == _autoFilledName) {
      _nameController.clear();
    }
    _autoFilledName = null;

    if (phone == null) {
      setState(() {
        _isLookingUpStudent = false;
        _lookupMessage = null;
        _lookupFailed = false;
      });
      return;
    }

    setState(() {
      _isLookingUpStudent = true;
      _lookupMessage = 'جارٍ البحث عن تسجيل سابق...';
      _lookupFailed = false;
    });

    _studentLookupDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _lookupStudent(phone, requestId),
    );
  }

  Future<void> _lookupStudent(String phone, int requestId) async {
    try {
      final studentName = await widget.controller.findStudentNameByPhone(phone);
      if (!mounted || requestId != _studentLookupRequest) return;

      if (studentName == null) {
        setState(() {
          _isLookingUpStudent = false;
          _lookupMessage = 'لا يوجد تسجيل سابق بهذا الرقم لدى هذا المعهد';
          _lookupFailed = false;
        });
        return;
      }

      if (_nameController.text.trim().isEmpty) {
        _nameController.text = studentName;
        _autoFilledName = studentName;
      }
      setState(() {
        _isLookingUpStudent = false;
        _lookupMessage = _autoFilledName == studentName
            ? 'تم العثور على الطالب وتعبئة اسمه'
            : 'تم العثور على الطالب، احتفظنا بالاسم الذي أدخلته';
        _lookupFailed = false;
      });
    } on Exception {
      if (!mounted || requestId != _studentLookupRequest) return;
      setState(() {
        _isLookingUpStudent = false;
        _lookupMessage = 'تعذر البحث عن الطالب. تحقق من الاتصال وحاول مجددًا';
        _lookupFailed = true;
      });
    }
  }

  void _onStudentNameChanged(String value) {
    if (_autoFilledName != null && value != _autoFilledName) {
      _autoFilledName = null;
    }
  }

  String? _validateStudentName(String? value) {
    final nameParts = (value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return nameParts.length < 4 ? 'أدخل الاسم الرباعي كاملًا' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final studentPhone = AppPhoneField.toE164(_phoneController.value);
    if (studentPhone == null) return;

    setState(() => _isSubmitting = true);
    final success = await widget.controller.createInPersonReservation(
      courseId: _courseId,
      studentName: _nameController.text.trim(),
      studentPhone: studentPhone,
      paymentOption: _paymentOption,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.errorMessage ?? 'تعذر إنشاء التسجيل الحضوري',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + bottomInset,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تسجيل طالب حضورياً',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _courseId,
                      decoration: const InputDecoration(labelText: 'الدورة'),
                      items: widget.courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course.id!,
                              child: Text(
                                '${course.title} · ${course.availableSeats} مقعد',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _courseId = value;
                                  if (_paymentOption == 'deposit' &&
                                      _selectedCourse.depositAmount <= 0) {
                                    _paymentOption = 'full';
                                  }
                                });
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الرباعي',
                        hintText: 'اكتب الاسم الأول واسم الأب والجد والعائلة',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateStudentName,
                      onChanged: _onStudentNameChanged,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPhoneField(
                      controller: _phoneController,
                      labelText: 'رقم الهاتف',
                      textInputAction: TextInputAction.next,
                      onChanged: _onStudentPhoneChanged,
                    ),
                    if (_lookupMessage != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (_isLookingUpStudent)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              _lookupFailed
                                  ? Icons.error_outline
                                  : _autoFilledName != null
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 16,
                              color: _lookupFailed
                                  ? AppColors.error
                                  : _autoFilledName != null
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _lookupMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: _lookupFailed
                                    ? AppColors.error
                                    : _autoFilledName != null
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentOption,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع والمبلغ',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'full',
                          child: Text(
                            'كامل · ${_selectedCourse.price.toStringAsFixed(0)} ريال',
                          ),
                        ),
                        if (_selectedCourse.depositAmount > 0)
                          DropdownMenuItem(
                            value: 'deposit',
                            child: Text(
                              'عربون · ${_selectedCourse.depositAmount.toStringAsFixed(0)} ريال',
                            ),
                          ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _paymentOption = value);
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.field,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المبلغ المسجل تلقائيًا',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
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
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        _isSubmitting ? 'جارٍ التسجيل...' : 'تأكيد التسجيل',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

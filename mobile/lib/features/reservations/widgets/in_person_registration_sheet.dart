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
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPhoneField(
                      controller: _phoneController,
                      labelText: 'رقم الهاتف',
                      textInputAction: TextInputAction.next,
                    ),
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

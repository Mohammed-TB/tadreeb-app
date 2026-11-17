import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
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
  final _phoneController = TextEditingController();
  final _amountPaidController = TextEditingController(text: '0');
  late String _courseId;
  String _paymentOption = 'full';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courses.first.id!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final success = await widget.controller.createInPersonReservation(
      courseId: _courseId,
      studentName: _nameController.text.trim(),
      studentPhone: _phoneController.text.trim(),
      paymentOption: _paymentOption,
      amountPaid: double.parse(_amountPaidController.text.trim()),
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
          
          decoration:BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12)
          ) ,
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
                                setState(() => _courseId = value);
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم الطالب'),
                      textInputAction: TextInputAction.next,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'أدخل اسم الطالب'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'أدخل رقم الهاتف'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentOption,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع المسجلة',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'full', child: Text('كامل')),
                        DropdownMenuItem(value: 'deposit', child: Text('عربون')),
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
                    TextFormField(
                      controller: _amountPaidController,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المدفوع',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        if (amount == null || !amount.isFinite || amount < 0) {
                          return 'أدخل مبلغاً صحيحاً';
                        }
                        final selected = widget.courses.firstWhere(
                          (course) => course.id == _courseId,
                        );
                        if (amount > selected.price) {
                          return 'المبلغ لا يمكن أن يتجاوز سعر الدورة';
                        }
                        return null;
                      },
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

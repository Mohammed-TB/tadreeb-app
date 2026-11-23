import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_phone_field.dart';
import '../../../core/utils/currency_formatter.dart';
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
  final _englishNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = AppPhoneField.createController();
  final _imagePicker = ImagePicker();
  late String _courseId;
  String _paymentMethod = 'cash';
  String _initialPaymentOption = 'full';
  Uint8List? _receiptBytes;
  String? _receiptName;
  String? _receiptContentType;
  bool _isSubmitting = false;
  bool _isLookingUpStudent = false;
  bool _lookupFailed = false;
  String? _lookupMessage;
  String? _autoFilledName;
  Timer? _studentLookupDebounce;
  int _studentLookupRequest = 0;

  CourseModel get _selectedCourse =>
      widget.courses.firstWhere((course) => course.id == _courseId);

  double get _selectedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courses.first.id!;
    final course = _selectedCourse;
    _amountController.text = course.price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _studentLookupDebounce?.cancel();
    _nameController.dispose();
    _englishNameController.dispose();
    _amountController.dispose();
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
    if (_paymentMethod == 'bankTransfer' && _receiptBytes == null) {
      setState(() => _isSubmitting = false);
      _showMessage('أرفق سند التحويل قبل تسجيل الطالب');
      return;
    }
    final success = await widget.controller.createInPersonReservation(
      courseId: _courseId,
      studentName: _nameController.text.trim(),
      studentPhone: studentPhone,
      paymentAmount: _selectedAmount,
      paymentMethod: _paymentMethod,
      studentEnglishName: _englishNameController.text.trim().isEmpty
          ? null
          : _englishNameController.text.trim(),
      receiptBytes: _receiptBytes,
      receiptName: _receiptName,
      receiptContentType: _receiptContentType,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    _showMessage(
      widget.controller.errorMessage ?? 'تعذر إنشاء التسجيل الحضوري',
    );
  }

  Future<void> _pickReceipt() async {
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
      if (mounted) _showMessage('تعذر اختيار السند: $error');
    }
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    final minimum = _selectedCourse.depositAmount > 0
        ? _selectedCourse.depositAmount
        : 0.01;
    if (amount == null ||
        !amount.isFinite ||
        amount < minimum ||
        amount > _selectedCourse.price) {
      return 'أدخل مبلغًا بين العربون والسعر الكامل';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                                  _amountController.text =
                                      (_selectedCourse.depositAmount > 0
                                              ? _selectedCourse.depositAmount
                                              : _selectedCourse.price)
                                          .toStringAsFixed(2);
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
                    if (_selectedCourse.requiresEnglishName) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _englishNameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم باللغة الإنجليزية',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'الاسم الإنجليزي مطلوب لهذه الدورة'
                            : null,
                      ),
                    ],
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
                    TextFormField(
                      controller: _amountController,
                      enabled: !_isSubmitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'المبلغ المستلم/المحوّل',
                        helperText:
                            'من ${CurrencyFormatter.format(_selectedCourse.depositAmount)} إلى ${CurrencyFormatter.format(_selectedCourse.price)}',
                      ),
                      validator: _validateAmount,
                      onChanged: (_) {
                        final amount = double.tryParse(
                          _amountController.text.trim(),
                        );
                        setState(() {
                          _initialPaymentOption =
                              amount == _selectedCourse.price
                              ? 'full'
                              : amount == _selectedCourse.depositAmount &&
                                    _selectedCourse.depositAmount > 0
                              ? 'deposit'
                              : 'custom';
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقدًا')),
                        DropdownMenuItem(
                          value: 'bankTransfer',
                          child: Text('تحويل بنكي'),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() {
                              if (value != null) {
                                _paymentMethod = value;
                                if (value == 'cash') {
                                  _receiptBytes = null;
                                  _receiptName = null;
                                  _receiptContentType = null;
                                }
                              }
                            }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _initialPaymentOption,
                      decoration: const InputDecoration(
                        labelText: 'اختيار مبلغ الدفعة',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'full',
                          child: Text(
                            'كامل الرسوم · ${CurrencyFormatter.format(_selectedCourse.price, decimalDigits: 0)}',
                          ),
                        ),
                        if (_selectedCourse.depositAmount > 0)
                          DropdownMenuItem(
                            value: 'deposit',
                            child: Text(
                              'عربون · ${CurrencyFormatter.format(_selectedCourse.depositAmount, decimalDigits: 0)}',
                            ),
                          ),
                        const DropdownMenuItem(
                          value: 'custom',
                          child: Text('مبلغ آخر'),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _initialPaymentOption = value;
                                if (value == 'full') {
                                  _amountController.text = _selectedCourse.price
                                      .toStringAsFixed(2);
                                } else if (value == 'deposit') {
                                  _amountController.text = _selectedCourse
                                      .depositAmount
                                      .toStringAsFixed(2);
                                }
                              });
                            },
                    ),
                    if (_paymentMethod == 'bankTransfer') ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickReceipt,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(_receiptName ?? 'رفع سند التحويل'),
                      ),
                    ],
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
                            CurrencyFormatter.format(
                              _selectedAmount,
                              decimalDigits: 0,
                            ),
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

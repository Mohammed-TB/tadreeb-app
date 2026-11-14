import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../courses/services/course_service.dart';
import '../widgets/add_course/course_basics_step.dart';
import '../widgets/add_course/course_fees_step.dart';
import '../widgets/add_course/course_form_navigation.dart';
import '../widgets/add_course/course_schedule_step.dart';

/// شاشة إضافة دورة جديدة للمعهد بمراحل متعددة
class AddInstituteCourseScreen extends StatefulWidget {
  const AddInstituteCourseScreen({super.key});

  @override
  State<AddInstituteCourseScreen> createState() =>
      _AddInstituteCourseScreenState();
}

class _AddInstituteCourseScreenState extends State<AddInstituteCourseScreen>
    with SingleTickerProviderStateMixin {
  final _basicsFormKey = GlobalKey<FormState>();
  final _scheduleFormKey = GlobalKey<FormState>();
  final _feesFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _imagePicker = ImagePicker();

  TabController? _tabsController;
  TabController get _controller =>
      _tabsController ??= TabController(length: _stepTitles.length, vsync: this)
        ..addListener(_onTabChanged);

  late DateTime _startDate;
  late DateTime _endDate;
  int _currentStep = 0;
  String? _category;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageContentType;
  bool _isPickingImage = false;
  bool _isSubmitting = false;
  List<String> _whatWillLearn = const [];
  List<String> _features = const [];

  static const _stepTitles = ['المعلومات', 'المواعيد', 'الرسوم'];

  @override
  void initState() {
    super.initState();
    final tomorrow = DateUtils.dateOnly(
      DateTime.now(),
    ).add(const Duration(days: 1));
    _startDate = tomorrow;
    _endDate = tomorrow.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _tabsController
      ?..removeListener(_onTabChanged)
      ..dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted && _currentStep != _controller.index) {
      setState(() => _currentStep = _controller.index);
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isPickingImage = true);
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
        _imageBytes = bytes;
        _imageName = image.name;
        _imageContentType = contentType;
      });
    } on Exception catch (error) {
      if (mounted) _showMessage('تعذر اختيار الصورة: $error');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageContentType = null;
    });
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate
        ? DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1))
        : _startDate.add(const Duration(days: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !mounted) return;
    setState(() {
      if (isStartDate) {
        _startDate = pickedDate;
        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = pickedDate;
      }
    });
  }

  bool _validateStep(int index) {
    final formState = switch (index) {
      0 => _basicsFormKey.currentState,
      1 => _scheduleFormKey.currentState,
      2 => _feesFormKey.currentState,
      _ => null,
    };
    final isValid =
        formState?.validate() ??
        switch (index) {
          0 =>
            _titleController.text.trim().length >= 3 &&
                _category != null &&
                _descriptionController.text.trim().isNotEmpty,
          1 =>
            int.tryParse(_capacityController.text.trim()) != null &&
                int.parse(_capacityController.text.trim()) > 0 &&
                _locationController.text.trim().isNotEmpty &&
                _endDate.isAfter(_startDate),
          2 =>
            (double.tryParse(_priceController.text.trim()) ?? -1) >= 0 &&
                (double.tryParse(_depositController.text.trim()) ?? -1) >= 0,
          _ => false,
        };

    if (!isValid) {
      if (formState == null) {
        _showMessage('أكمل بيانات خطوة "${_stepTitles[index]}" أولاً');
      }
      return false;
    }
    if (index == 2) {
      final price = double.tryParse(_priceController.text.trim());
      final deposit = double.tryParse(_depositController.text.trim());
      if (price != null && deposit != null && deposit > price) {
        _showMessage('لا يمكن أن يكون العربون أكبر من سعر الدورة');
        return false;
      }
    }
    return true;
  }

  void _nextStep() {
    final currentIndex = _controller.index;
    if (!_validateStep(currentIndex)) return;
    if (currentIndex < _stepTitles.length - 1) {
      _controller.animateTo(
        currentIndex + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_controller.index > 0) {
      _controller.animateTo(
        _controller.index - 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    for (var index = 0; index < _stepTitles.length; index++) {
      if (!_validateStep(index)) {
        _controller.animateTo(index);
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<CourseService>().createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category!,
        price: double.parse(_priceController.text.trim()),
        depositAmount: double.parse(_depositController.text.trim()),
        capacity: int.parse(_capacityController.text.trim()),
        startDate: _startDate,
        endDate: _endDate,
        location: _locationController.text.trim(),
        whatWillLearn: _whatWillLearn,
        features: _features,
        imageBytes: _imageBytes,
        imageName: _imageName,
        imageContentType: _imageContentType,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount < 0) {
      return 'أدخل مبلغًا صحيحًا';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStep;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        title: Text(
          'إضافة دورة',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: IgnorePointer(
            ignoring: _isSubmitting,
            child: CourseFormStepProgress(
              steps: _stepTitles,
              currentStep: currentStep,
              onStepSelected: (index) => _controller.animateTo(
                index,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ),
      ),
      body: IgnorePointer(
        ignoring: _isSubmitting,
        child: TabBarView(
          controller: _controller,
          children: [
            CourseBasicsStep(
              formKey: _basicsFormKey,
              titleController: _titleController,
              descriptionController: _descriptionController,
              category: _category,
              onCategoryChanged: (value) => setState(() => _category = value),
              imageBytes: _imageBytes,
              isPickingImage: _isPickingImage,
              onPickImage: _pickImage,
              onRemoveImage: _removeImage,
              onWhatWillLearnChanged: (items) => _whatWillLearn = items,
              onFeaturesChanged: (items) => _features = items,
            ),
            CourseScheduleStep(
              formKey: _scheduleFormKey,
              startDate: _startDate,
              endDate: _endDate,
              onSelectStartDate: () => _selectDate(isStartDate: true),
              onSelectEndDate: () => _selectDate(isStartDate: false),
              capacityController: _capacityController,
              locationController: _locationController,
            ),
            CourseFeesStep(
              formKey: _feesFormKey,
              priceController: _priceController,
              depositController: _depositController,
              validateAmount: _validateAmount,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: CourseFormStepActions(
            isFirstStep: currentStep == 0,
            isLastStep: currentStep == _stepTitles.length - 1,
            isSubmitting: _isSubmitting,
            onPrevious: _previousStep,
            onNext: _nextStep,
          ),
        ),
      ),
    );
  }
}

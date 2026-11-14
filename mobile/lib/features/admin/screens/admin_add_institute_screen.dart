import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/button.dart';
import '../services/admin_institute_service.dart';
import '../widgets/admin_institute_form_tabs.dart';

class AdminAddInstituteScreen extends StatefulWidget {
  const AdminAddInstituteScreen({super.key});

  @override
  State<AdminAddInstituteScreen> createState() =>
      _AdminAddInstituteScreenState();
}

class _AdminAddInstituteScreenState extends State<AdminAddInstituteScreen>
    with SingleTickerProviderStateMixin {
  static const _maxLogoSizeBytes = 5 * 1024 * 1024;

  final _formData = AdminInstituteFormData();
  final _imagePicker = ImagePicker();

  late final TabController _tabController;
  late final AdminInstituteService _service;
  int _currentTab = 0;
  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoContentType;
  String? _logoError;
  bool _isPickingLogo = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = AdminInstituteService(apiClient: context.read<ApiClient>());
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    _formData.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted || _currentTab == _tabController.index) return;
    setState(() => _currentTab = _tabController.index);
  }

  Future<void> _pickLogo() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isPickingLogo = true;
      _logoError = null;
    });

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      final contentType = _contentTypeFor(image.name);
      if (contentType == null) {
        setState(
          () => _logoError = 'نوع الصورة غير مدعوم. اختر JPG أو PNG أو WEBP.',
        );
        return;
      }

      final imageLength = await image.length();
      if (!mounted) return;
      if (imageLength > _maxLogoSizeBytes) {
        setState(() => _logoError = 'يجب ألا يتجاوز حجم الصورة 5 ميجابايت.');
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _logoBytes = bytes;
        _logoName = image.name;
        _logoContentType = contentType;
        _logoError = null;
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _logoError = 'تعذر اختيار الصورة. تحقق من صلاحية الوصول للصور.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingLogo = false);
    }
  }

  String? _contentTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  void _removeLogo() {
    setState(() {
      _logoBytes = null;
      _logoName = null;
      _logoContentType = null;
      _logoError = null;
    });
  }

  Future<void> _continueOrSubmit() async {
    FocusScope.of(context).unfocus();

    if (_currentTab == 0) {
      if (_formData.instituteFormKey.currentState?.validate() ?? false) {
        _tabController.animateTo(1);
      }
      return;
    }

    if (!(_formData.instituteFormKey.currentState?.validate() ?? false)) {
      _tabController.animateTo(0);
      return;
    }
    if (!(_formData.ownerFormKey.currentState?.validate() ?? false)) return;

    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _service.createInstitute(
        instituteName: _formData.instituteName.text,
        institutePhone: _formData.institutePhone.text,
        instituteAddress: _formData.instituteAddress.text,
        instituteDescription: _formData.instituteDescription.text,
        instituteEmail: _formData.instituteEmail.text,
        ownerName: _formData.ownerName.text,
        ownerEmail: _formData.ownerEmail.text,
        ownerPhone: _formData.ownerPhone.text,
        ownerPassword: _formData.ownerPassword.text,
        logoBytes: _logoBytes,
        logoName: _logoName,
        logoContentType: _logoContentType,
      );
      if (!mounted) return;
      _formData.ownerPassword.clear();
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            'إضافة معهد',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: AdminInstituteFormTabs(
                tabController: _tabController,
                currentTab: _currentTab,
                formData: _formData,
                logoBytes: _logoBytes,
                logoError: _logoError,
                isPickingLogo: _isPickingLogo,
                isSubmitting: _isSubmitting,
                onPickLogo: _pickLogo,
                onRemoveLogo: _removeLogo,
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Button(
          text: _currentTab == 0 ? 'التالي' : 'إضافة المعهد',
          variant: AppButtonVariant.primary,
          isLoading: _isSubmitting,
          onTap: _isSubmitting ? null : _continueOrSubmit,
        ),
      ),
    );
  }
}

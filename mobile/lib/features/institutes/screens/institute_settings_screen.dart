import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_skeletons.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/institute_service.dart';

class InstituteSettingsScreen extends StatefulWidget {
  const InstituteSettingsScreen({super.key});

  @override
  State<InstituteSettingsScreen> createState() =>
      _InstituteSettingsScreenState();
}

class _InstituteSettingsScreenState extends State<InstituteSettingsScreen> {
  static const _maxLogoSizeBytes = 5 * 1024 * 1024;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingLogo = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String? _logoUrl;
  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoContentType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = !_hasLoaded;
      _errorMessage = null;
    });
    try {
      final ownerUserId = context.read<AuthController>().currentUser?.id;
      if (ownerUserId == null || ownerUserId.isEmpty) {
        setState(() => _errorMessage = 'يرجى تسجيل الدخول مجددًا');
        return;
      }
      final institute = await context.read<InstituteService>().getMyInstitute(
        ownerUserId: ownerUserId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      _nameController.text = institute.name;
      _descriptionController.text = institute.description ?? '';
      _phoneController.text = institute.phone;
      _emailController.text = institute.email ?? '';
      _addressController.text = institute.address;
      _logoUrl = institute.imageUrl;
      setState(() {
        _hasLoaded = true;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    setState(() {
      _isPickingLogo = true;
      _errorMessage = null;
    });
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;

      final contentType = _contentTypeFor(image.name);
      if (contentType == null) {
        setState(() => _errorMessage = 'اختر صورة بصيغة JPG أو PNG أو WEBP.');
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxLogoSizeBytes) {
        setState(() => _errorMessage = 'يجب ألا يتجاوز حجم الصورة 5 ميجابايت.');
        return;
      }

      setState(() {
        _logoBytes = bytes;
        _logoName = image.name;
        _logoContentType = contentType;
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _errorMessage =
              'تعذر اختيار الصورة. تحقق من صلاحية الوصول للصور.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingLogo = false);
    }
  }

  String? _contentTypeFor(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      setState(
        () => _errorMessage = 'الاسم ورقم الهاتف والعنوان حقول إلزامية.',
      );
      return;
    }
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone)) {
      setState(
        () => _errorMessage = 'أدخل رقم هاتف صحيحًا بصيغة دولية مثل +967...',
      );
      return;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(
        () => _errorMessage = 'أدخل بريدًا إلكترونيًا صحيحًا أو اتركه فارغًا.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final ownerUserId = context.read<AuthController>().currentUser?.id;
      if (ownerUserId == null || ownerUserId.isEmpty) {
        setState(() => _errorMessage = 'يرجى تسجيل الدخول مجددًا');
        return;
      }
      final service = context.read<InstituteService>();
      if (_logoBytes != null && _logoName != null && _logoContentType != null) {
        final institute = await service.uploadMyInstituteLogo(
          ownerUserId: ownerUserId,
          imageBytes: _logoBytes!,
          fileName: _logoName!,
          contentType: _logoContentType!,
        );
        _logoUrl = institute.imageUrl;
        _logoBytes = null;
        _logoName = null;
        _logoContentType = null;
      }

      await service.updateMyInstitute(
        ownerUserId: ownerUserId,
        name: name,
        description: _descriptionController.text.trim(),
        phone: phone,
        email: email,
        address: address,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المعهد')));
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيانات المعهد'),
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: _isLoading || _isSaving
                  ? null
                  : () => _load(forceRefresh: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const AppSkeletonForm(fieldCount: 6)
            : !_hasLoaded
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage ?? 'تعذر تحميل بيانات المعهد',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'بيانات المعهد',
                              style: AppTypography.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'حدّث المعلومات التي تظهر للطلاب في التطبيق.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildLogoPicker(),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _nameController,
                          enabled: !_isSaving,
                          maxLength: 150,
                          decoration: const InputDecoration(
                            labelText: 'اسم المعهد',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _phoneController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: '+967...',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _emailController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _addressController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _descriptionController,
                          enabled: !_isSaving,
                          maxLength: 1000,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'نبذة عن المعهد',
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSaving ? 'جارٍ الحفظ...' : 'حفظ بيانات المعهد',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    final hasLogo = _logoBytes != null || (_logoUrl?.isNotEmpty ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('شعار المعهد', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.field,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: _logoBytes != null
                ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                : hasLogo
                ? Image.network(
                    _logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _logoPlaceholder(),
                  )
                : _logoPlaceholder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: _isSaving || _isPickingLogo ? null : _pickLogo,
          icon: _isPickingLogo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(hasLogo ? 'تغيير الشعار' : 'اختيار شعار'),
        ),
        Text(
          'JPG أو PNG أو WEBP • حتى 5 ميجابايت',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _logoPlaceholder() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.apartment_rounded,
        size: 40,
        color: AppColors.textSecondary,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'لا يوجد شعار للمعهد',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

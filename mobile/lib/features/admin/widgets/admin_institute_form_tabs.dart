import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import 'admin_institute_form_section.dart';
import 'admin_institute_logo_picker.dart';

class AdminInstituteFormData {
  final instituteFormKey = GlobalKey<FormState>();
  final ownerFormKey = GlobalKey<FormState>();
  final instituteName = TextEditingController();
  final institutePhone = TextEditingController();
  final instituteAddress = TextEditingController();
  final instituteDescription = TextEditingController();
  final instituteEmail = TextEditingController();
  final ownerName = TextEditingController();
  final ownerEmail = TextEditingController();
  final ownerPhone = TextEditingController();
  final ownerPassword = TextEditingController();

  void dispose() {
    instituteName.dispose();
    institutePhone.dispose();
    instituteAddress.dispose();
    instituteDescription.dispose();
    instituteEmail.dispose();
    ownerName.dispose();
    ownerEmail.dispose();
    ownerPhone.dispose();
    ownerPassword.dispose();
  }
}

class AdminInstituteFormTabs extends StatelessWidget {
  const AdminInstituteFormTabs({
    super.key,
    required this.tabController,
    required this.currentTab,
    required this.formData,
    required this.logoBytes,
    required this.logoError,
    required this.isPickingLogo,
    required this.isSubmitting,
    required this.onPickLogo,
    required this.onRemoveLogo,
  });

  final TabController tabController;
  final int currentTab;
  final AdminInstituteFormData formData;
  final Uint8List? logoBytes;
  final String? logoError;
  final bool isPickingLogo;
  final bool isSubmitting;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: IgnorePointer(
            ignoring: isSubmitting,
            child: TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.labelLarge,
              tabs: const [
                Tab(text: 'بيانات المعهد'),
                Tab(text: 'حساب صاحب المعهد'),
              ],
            ),
          ),
        ),
        Expanded(
          child: IgnorePointer(
            ignoring: isSubmitting,
            child: IndexedStack(
              index: currentTab,
              children: [_buildInstituteTab(), _buildOwnerTab()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstituteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: formData.instituteFormKey,
        child: AdminInstituteFormSection(
          title: 'بيانات المعهد',
          icon: Icons.business_outlined,
          description: 'هذه البيانات ستظهر للمتدربين في التطبيق.',
          children: [
            _buildTextField(
              controller: formData.instituteName,
              label: 'اسم المعهد',
              icon: Icons.business_outlined,
              validator: (value) => _requiredMinLengthValidator(value, 2),
            ),
            _buildTextField(
              controller: formData.institutePhone,
              label: 'رقم التواصل',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _requiredValidator,
            ),
            _buildTextField(
              controller: formData.instituteAddress,
              label: 'العنوان',
              icon: Icons.location_on_outlined,
              validator: _requiredValidator,
            ),
            _buildTextField(
              controller: formData.instituteDescription,
              label: 'نبذة عن المعهد (اختياري)',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            _buildTextField(
              controller: formData.instituteEmail,
              label: 'البريد الإلكتروني (اختياري)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _optionalEmailValidator,
            ),
            AdminInstituteLogoPicker(
              imageBytes: logoBytes,
              isPicking: isPickingLogo,
              errorMessage: logoError,
              onPick: onPickLogo,
              onRemove: onRemoveLogo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: formData.ownerFormKey,
        child: AdminInstituteFormSection(
          title: 'حساب صاحب المعهد',
          icon: Icons.person_outline,
          description: 'سيستخدم صاحب المعهد هذه البيانات لتسجيل الدخول.',
          children: [
            _buildTextField(
              controller: formData.ownerName,
              label: 'اسم صاحب المعهد',
              icon: Icons.person_outline,
              validator: (value) => _requiredMinLengthValidator(value, 2),
            ),
            _buildTextField(
              controller: formData.ownerEmail,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _requiredEmailValidator,
            ),
            _buildTextField(
              controller: formData.ownerPhone,
              label: 'رقم الهاتف (اختياري)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: formData.ownerPassword,
              label: 'كلمة المرور',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                if (value.length < 8) {
                  return 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: obscureText ? 1 : maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  String? _requiredMinLengthValidator(String? value, int minLength) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'هذا الحقل مطلوب';
    if (trimmed.length < minLength) {
      return 'يجب ألا يقل الاسم عن $minLength أحرف';
    }
    return null;
  }

  String? _requiredEmailValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;
    if (!_isValidEmail(value!.trim())) return 'أدخل بريداً إلكترونياً صحيحاً';
    return null;
  }

  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_isValidEmail(value.trim())) return 'أدخل بريداً إلكترونياً صحيحاً';
    return null;
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}

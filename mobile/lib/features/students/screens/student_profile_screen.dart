import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/student_profile_model.dart';
import '../services/student_profile_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _englishNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _englishNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await context.read<StudentProfileService>().getProfile();
      if (!mounted) return;
      _setProfile(profile);
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setProfile(StudentProfileModel profile) {
    _nameController.text = profile.name;
    _englishNameController.text = profile.englishName ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final profile = await context.read<StudentProfileService>().updateProfile(
        name: _nameController.text.trim(),
        englishName: _englishNameController.text.trim(),
      );
      if (!mounted) return;
      _setProfile(profile);
      context.read<AuthController>().updateCurrentUserName(profile.name);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث الملف الشخصي')));
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateFourPartName(String? value) {
    if ((value ?? '').trim().split(RegExp(r'\s+')).length < 4) {
      return 'أدخل الاسم الرباعي كاملًا';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الرباعي',
                    ),
                    validator: _validateFourPartName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _englishNameController,
                    enabled: !_isSaving,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'الاسم باللغة الإنجليزية (اختياري)',
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ التعديلات'),
                  ),
                ],
              ),
            ),
    );
  }
}

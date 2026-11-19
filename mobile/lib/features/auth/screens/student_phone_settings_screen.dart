import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../../../core/widgets/app_phone_field.dart';
import '../controllers/auth_controller.dart';

class StudentPhoneSettingsScreen extends StatefulWidget {
  const StudentPhoneSettingsScreen({super.key});

  @override
  State<StudentPhoneSettingsScreen> createState() =>
      _StudentPhoneSettingsScreenState();
}

class _StudentPhoneSettingsScreenState
    extends State<StudentPhoneSettingsScreen> {
  final _phoneController = AppPhoneField.createController();
  final _codeController = TextEditingController();
  String? _pendingPhone;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = AppPhoneField.toE164(_phoneController.value);
    if (phone == null) return;

    final auth = context.read<AuthController>();
    final sent = await auth.requestPhoneLink(phone: phone);
    if (!mounted) return;
    if (sent) {
      setState(() {
        _pendingPhone = phone;
        _codeSent = true;
      });
    } else {
      _showMessage(auth.errorMessage ?? 'تعذر إرسال رمز التحقق');
    }
  }

  Future<void> _verifyCode() async {
    final phone = _pendingPhone;
    final code = _codeController.text.trim();
    if (phone == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('أدخل رمز التحقق المكون من 6 أرقام');
      return;
    }

    final auth = context.read<AuthController>();
    final linkedCount = await auth.verifyPhoneLink(
      phone: phone,
      code: code,
    );
    if (!mounted) return;

    if (linkedCount == null) {
      _showMessage(auth.errorMessage ?? 'تعذر التحقق من الرقم');
      return;
    }

    context.read<AppDataChangeBus>().notifyChanged(
          AppDataDomain.reservations,
          AppDataChangeOrigin.phoneLink,
          audience: AppDataAudience.student,
        );
    _showMessage(
      linkedCount == 0
          ? 'تم ربط رقم الهاتف بنجاح'
          : 'تم ربط رقم الهاتف وربط $linkedCount تسجيلات سابقة',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('ربط رقم الهاتف')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    user?.isPhoneVerified == true
                        ? Icons.verified_rounded
                        : Icons.phone_android_rounded,
                    color: user?.isPhoneVerified == true
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      user?.isPhoneVerified == true
                          ? 'رقمك الموثق: ${user?.phone ?? ""}'
                          : 'لم يتم ربط رقم هاتف بعد',
                      style: AppTypography.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPhoneField(
              controller: _phoneController,
              labelText: 'رقم الهاتف',
              hintText: 'أدخل رقم هاتف واتساب',
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: auth.isLoading ? null : _requestCode,
              child: const Text('إرسال رمز التحقق عبر واتساب'),
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !auth.isLoading,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق',
                  hintText: 'أدخل الرمز المكون من 6 أرقام',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: auth.isLoading ? null : _verifyCode,
                child: const Text('تحقق واربط الرقم'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

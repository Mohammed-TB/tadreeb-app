import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/text_filed_form.dart';
import '../../../core/widgets/button.dart';

class FormRegister extends StatefulWidget {
  const FormRegister({
    super.key,
    required this.register,
    required this.googleRegister,
  });

  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  })
  register;
  final Future<void> Function() googleRegister;

  @override
  State<FormRegister> createState() => _FormRegisterState();
}

class _FormRegisterState extends State<FormRegister> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isLoading = false;

  // إنشاء الحساب
  Future<void> _handleRegister() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        message: 'حدث خطأ أثناء إنشاء الحساب، حاول مرة أخرى',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // إظهار وإخفاء كلمة المرور
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _togglePasswordConfirmVisibility() {
    setState(() {
      _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
    });
  }

  // رسالة للمستخدم
  void _showMessage({required String message, bool isError = false}) {
    Flushbar(
      message: message,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  Future<void> _handleGoogleRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.googleRegister();
    } catch (error) {
      if (!mounted) return;
      _showMessage(message: error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // الانتقال إلى تسجيل الدخول
  void _goToLogin() {
    context.go('/login');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -35),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // الاسم
                CustomTextFiledForm(
                  hinText: 'الاسم',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }

                    if (value.trim().length < 8) {
                      return 'الاسم يجب أن يكون 8 أحرف على الأقل';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // البريد الإلكتروني
                CustomTextFiledForm(
                  hinText: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }

                    if (!RegExp(
                      r'^[^@]+@[^@]+\.[^@]+$',
                    ).hasMatch(value.trim())) {
                      return 'البريد الإلكتروني غير صحيح';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // كلمة المرور
                Stack(
                  children: [
                    CustomTextFiledForm(
                      hinText: 'كلمة المرور',
                      icon: Icons.key_outlined,
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'كلمة المرور مطلوبة';
                        }

                        if (value.length < 8) {
                          return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                        }

                        return null;
                      },
                    ),

                    Positioned(
                      top: 10,
                      left: 4,
                      child: InkWell(
                        onTap: _togglePasswordVisibility,
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // تأكيد كلمة المرور
                Stack(
                  children: [
                    CustomTextFiledForm(
                      hinText: 'تأكيد كلمة المرور',
                      icon: Icons.key_outlined,
                      controller: _passwordConfirmController,
                      obscureText: !_isPasswordConfirmVisible,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'تأكيد كلمة المرور مطلوب';
                        }

                        if (value != _passwordController.text) {
                          return 'كلمات المرور غير متطابقة';
                        }

                        return null;
                      },
                    ),

                    Positioned(
                      top: 10,
                      left: 4,
                      child: InkWell(
                        onTap: _togglePasswordConfirmVisibility,
                        child: Icon(
                          _isPasswordConfirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // زر إنشاء الحساب
                Button(
                  text: 'إنشاء حساب',
                  onTap: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                  height: 48,
                ),

                const SizedBox(height: AppSpacing.lg),

                // الفاصل
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        'أو',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // التسجيل عبر Google
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleRegister,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/google_logo.svg',
                          width: 24,
                          height: 24,
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        Text(
                          'التسجيل عبر Google',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // الانتقال إلى تسجيل الدخول
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب؟ ',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goToLogin,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'تسجيل الدخول',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../widgets/form_register.dart';
import '../widgets/top_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Future<void> _register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    // التحقق من تطابق كلمتي المرور
    if (password != passwordConfirm) {
      await _showMessage('كلمتا المرور غير متطابقتين', isSuccess: false);
      return;
    }

    final authController = context.read<AuthController>();

    final success = await authController.register(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      await _showMessage('تم إنشاء الحساب بنجاح', isSuccess: true);

      if (!mounted) return;

      final user = authController.currentUser;
      if (user != null) context.go(_destinationFor(user));
    } else {
      await _showMessage(
        authController.errorMessage ?? 'حدث خطأ أثناء إنشاء الحساب',
        isSuccess: false,
      );
    }
  }

  Future<void> _googleRegister() async {
    final authController = context.read<AuthController>();
    final success = await authController.loginWithGoogle();
    if (!mounted) return;

    if (success) {
      final user = authController.currentUser;
      if (user != null) {
        await _showMessage('تم تسجيل الدخول بنجاح، أهلاً ${user.name}!');
        if (mounted) context.go(_destinationFor(user));
      }
    } else {
      await _showMessage(
        authController.errorMessage ?? 'تعذر التسجيل باستخدام Google',
        isSuccess: false,
      );
    }
  }

  String _destinationFor(UserModel user) => switch (user.role) {
    UserRole.student => '/home_screen',
    UserRole.instituteOwner => '/institute_dashboard',
    UserRole.admin => '/admin_dashboard',
  };

  Future<void> _showMessage(String message, {bool isSuccess = true}) async {
    await Flushbar(
      message: message,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error_outline,
        color: Colors.white,
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red.shade700,
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  const TopHeader(
                    title: 'إنشاء حساب',
                    subTitle: 'أنشئ حسابًا واكتشف الدورات',
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: InkWell(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              FormRegister(
                register: _register,
                googleRegister: _googleRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

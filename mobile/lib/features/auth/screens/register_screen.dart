import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
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
      await _showMessage(
        'كلمتا المرور غير متطابقتين',
        isSuccess: false,
      );
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
      await _showMessage(
        'تم إنشاء الحساب بنجاح',
        isSuccess: true,
      );

      if (!mounted) return;

      context.go('/home_screen');
    } else {
      await _showMessage(
        authController.errorMessage ??
            'حدث خطأ أثناء إنشاء الحساب',
        isSuccess: false,
      );
    }
  }

  Future<void> _showMessage(
    String message, {
    required bool isSuccess,
  }) async {
    await Flushbar(
      message: message,
      icon: Icon(
        isSuccess
            ? Icons.check_circle
            : Icons.error_outline,
        color: Colors.white,
      ),
      backgroundColor:
          isSuccess ? Colors.green : Colors.red.shade700,
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
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              FormRegister(register: _register),
            ],
          ),
        ),
      ),
    );
  }
}
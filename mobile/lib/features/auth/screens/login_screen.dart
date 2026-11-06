import 'package:flutter/material.dart';
import 'package:project_1/features/auth/widgets/form_login.dart';
import 'package:project_1/features/auth/widgets/topHeader.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

import 'package:go_router/go_router.dart';
import 'package:another_flushbar/flushbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final authController = context.read<AuthController>();

    final success = await authController.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (!mounted) return;

    if (success) {
      // الانتقال إلى الصفحة الرئيسية
      context.go('/home_screen');

      // رسالة نجاح تسجيل الدخول
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Flushbar(
          message: 'تم تسجيل الدخول بنجاح، أهلاً بك!',
          icon: const Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          borderRadius: BorderRadius.circular(12),
          margin: const EdgeInsets.all(16),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      });
    } else {
      // رسالة فشل تسجيل الدخول
      Flushbar(
        message:
            authController.errorMessage ??
            'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        icon: const Icon(Icons.error_outline, color: Colors.white),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        borderRadius: BorderRadius.circular(12),
        margin: const EdgeInsets.all(16),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TopHeader(title: 'تسجيل الدخول', subTitle: 'سجل دخولك للمتابعة'),
              FormLogin(login: _login),
            ],
          ),
        ),
      ),
    );
  }
}

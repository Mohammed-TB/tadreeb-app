import 'package:flutter/material.dart';
import 'package:project_1/features/auth/widgets/form_login.dart';
import 'package:project_1/features/auth/widgets/top_header.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:another_flushbar/flushbar.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.showLoginRequiredMessage = false});

  final bool showLoginRequiredMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showLoginRequiredMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMessage('يرجى تسجيل الدخول للاستمرار', isSuccess: false);
        }
      });
    }
  }

  Future<void> _login({required String email, required String password}) async {
    final authController = context.read<AuthController>();

    final success = await authController.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      final user = authController.currentUser;

      if (user == null) return;

      _completeLogin(user);
    } else {
      _showMessage(
        authController.errorMessage ??
            'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        isSuccess: false,
      );
    }
  }

  Future<void> _googleLogin() async {
    final authController = context.read<AuthController>();
    final success = await authController.loginWithGoogle();
    if (!mounted) return;

    final user = authController.currentUser;
    if (success && user != null) {
      _completeLogin(user);
    } else {
      _showMessage(
        authController.errorMessage ?? 'تعذر تسجيل الدخول باستخدام Google',
        isSuccess: false,
      );
    }
  }

  void _completeLogin(UserModel user) {
    final destination = switch (user.role) {
      UserRole.student => '/home_screen',
      UserRole.instituteOwner => '/institute_dashboard',
      UserRole.admin => '/admin_dashboard',
    };
    context.go(destination);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showMessage('تم تسجيل الدخول بنجاح، أهلاً ${user.name}!');
      }
    });
  }

  void _continueAsGuest() {
    context.read<AuthController>().continueAsGuest();
    context.go('/home_screen');
  }

  void _showMessage(String message, {bool isSuccess = true}) {
    Flushbar(
      message: message,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error_outline,
        color: Colors.white,
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red.shade700,
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TopHeader(
                title: 'مرحبًا بعودتك',
                subTitle: 'سجّل الدخول لمتابعة دوراتك وتسجيلاتك بسهولة.',
              ),
              FormLogin(login: _login, googleLogin: _googleLogin),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton.icon(
                  onPressed: _continueAsGuest,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('الدخول كزائر'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

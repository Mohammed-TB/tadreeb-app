import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_1/features/auth/widgets/form_register.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../widgets/topHeader.dart';
import 'package:go_router/go_router.dart';

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
    final authController = context.read<AuthController>();

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
    );

    final success = await authController.register(user);

    if (!mounted) return;

    if (success) {
      // الانتقال إلى الصفحة الرئيسية عبر GoRouter
      context.go('/home_screen');

      // عرض رسالة النجاح
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Flushbar(
          message: 'تم إنشاء الحساب بنجاح',
          icon: const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          borderRadius: BorderRadius.circular(12),
          margin: const EdgeInsets.all(16),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ??
                'حدث خطأ أثناء إنشاء الحساب',
          ),
        ),
      );
    }
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
                  TopHeader(
                    title: 'إنشاء حساب',
                    subTitle: 'أنشئ حسابًا واكتشف الدورات',
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: InkWell(
                      onTap: Navigator.of(context).pop,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle

                        ),
                         child: Icon(Icons.arrow_back,size: 20,),
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

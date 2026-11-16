import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 5);

  late final AnimationController _progressController;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );
    _progress = Tween<double>(begin: 0.01, end: 1).animate(_progressController);
    unawaited(_navigateAfterSplash());
  }

  Future<void> _navigateAfterSplash() async {
    final authController = context.read<AuthController>();
    try {
      await Future.wait<void>([
        _progressController.forward().orCancel,
        _waitForSessionInitialization(authController),
      ]);
    } on TickerCanceled {
      return;
    }

    if (!mounted) return;

    final destination = switch (authController.currentUser?.role) {
      UserRole.student => '/home_screen',
      UserRole.instituteOwner => '/institute_dashboard',
      UserRole.admin => '/admin_dashboard',
      null => '/login',
    };
    context.go(destination);
  }

  Future<void> _waitForSessionInitialization(AuthController authController) {
    if (!authController.isInitializing) return Future<void>.value();

    final completer = Completer<void>();
    void onAuthChanged() {
      if (authController.isInitializing) return;
      authController.removeListener(onAuthChanged);
      completer.complete();
    }

    authController.addListener(onAuthChanged);
    return completer.future;
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'تدريب',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'جارٍ تجهيز رحلتك التعليمية',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    final progress = _progress.value;
                    final percentage = (progress * 100).floor().clamp(1, 100);
                    return Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final iconOffset =
                                (constraints.maxWidth - 32) * progress;
                            return SizedBox(
                              height: 48,
                              child: Stack(
                                children: [
                                  PositionedDirectional(
                                    start: 0,
                                    end: 0,
                                    bottom: 8,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 8,
                                        color: AppColors.primaryLight,
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SizedBox(
                                          width:
                                              constraints.maxWidth * progress,
                                          height: 8,
                                          child: const ColoredBox(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  PositionedDirectional(
                                    start: iconOffset,
                                    top: 0,
                                    child: const Icon(
                                      Icons.directions_walk_outlined,
                                      size: 32,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

import '../models/onboarding.models.dart';
import '../widgets/on_boarding_button.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  // الانتقال إلى صفحة تسجيل الدخول
  void _goToLogin() {
    context.go('/login');
  }

  // الانتقال إلى الصفحة التالية
  void nextPage() {
    if (currentIndex < onBoardingList.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  // الرجوع إلى الصفحة السابقة
  void previousPage() {
    if (currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // تخطي صفحات التعريف
  void skipOnboarding() {
    _goToLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // صفحات التعريف
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onBoardingList.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = onBoardingList[index];

                  return _buildOnboardingPage(page);
                },
              ),
            ),

            // مؤشرات الصفحات
            _buildPageIndicators(),

            // أزرار التنقل
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // تصميم صفحة التعريف
  Widget _buildOnboardingPage(dynamic page) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(page.icon, size: 120, color: AppColors.primary),

              const SizedBox(height: AppSpacing.xxxl),

              Text(
                page.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                page.description,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // مؤشرات الصفحات
  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(onBoardingList.length, (index) {
          final isSelected = currentIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            width: isSelected ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }

  // أزرار التنقل
  Widget _buildNavigationButtons() {
    final isFirstPage = currentIndex == 0;
    final isLastPage = currentIndex == onBoardingList.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (!isFirstPage) ...[
                Expanded(
                  child: OnBoardingButton(
                    text: 'السابق',
                    isPrimary: false,
                    onTap: previousPage,
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),
              ],

              Expanded(
                child: OnBoardingButton(
                  text: isLastPage ? 'ابدأ الآن' : 'التالي',
                  isPrimary: true,
                  onTap: nextPage,
                ),
              ),
            ],
          ),

          if (isFirstPage) ...[
            const SizedBox(height: AppSpacing.xs),

            TextButton(
              onPressed: skipOnboarding,
              child: Text(
                'تخطي',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

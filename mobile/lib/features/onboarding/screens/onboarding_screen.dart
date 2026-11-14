import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/onboarding.models.dart';
import '../widgets/on_boarding_button.dart';

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

  void _goToLogin() {
    context.go('/login');
  }

  void nextPage() {
    if (currentIndex < onBoardingList.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void previousPage() {
    if (currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

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
            _buildTopBar(),
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
                  return _buildOnboardingPage(onBoardingList[index], index);
                },
              ),
            ),
            _buildPageIndicators(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: skipOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
            child: Text(
              'تخطي',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(currentIndex),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentIndex + 1} من ${onBoardingList.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnBoarding page, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize = constraints.maxHeight < 480 ? 190.0 : 230.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIllustration(page, index, illustrationSize),
                  SizedBox(
                    height: constraints.maxHeight < 480
                        ? AppSpacing.lg
                        : AppSpacing.xxxl,
                  ),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIllustration(OnBoarding page, int index, double size) {
    final isCurrentPage = currentIndex == index;

    return AnimatedScale(
      scale: isCurrentPage ? 1 : 0.88,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: isCurrentPage ? 1 : 0.72,
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: page.color,
                  borderRadius: BorderRadius.circular(size * 0.24),
                ),
              ),
              Positioned(
                top: size * 0.12,
                left: size * 0.13,
                child: _decorationDot(size * 0.12, AppColors.accentLight),
              ),
              Positioned(
                bottom: size * 0.12,
                right: size * 0.12,
                child: _decorationDot(size * 0.16, AppColors.primaryLight),
              ),
              Container(
                width: size * 0.52,
                height: size * 0.52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  size: size * 0.27,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                top: size * 0.21,
                right: size * 0.19,
                child: Icon(
                  Icons.auto_awesome,
                  size: size * 0.1,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decorationDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(onBoardingList.length, (index) {
          final isSelected = currentIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            width: isSelected ? 28 : 8,
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
      child: Row(
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: OnBoardingButton(
                key: ValueKey(isLastPage),
                text: isLastPage ? 'ابدأ الآن' : 'التالي',
                isPrimary: true,
                onTap: nextPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

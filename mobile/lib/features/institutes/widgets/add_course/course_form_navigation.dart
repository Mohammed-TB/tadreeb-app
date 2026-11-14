import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class CourseFormStepProgress extends StatelessWidget {
  const CourseFormStepProgress({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepSelected,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < steps.length; index++)
                Expanded(
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => onStepSelected(index),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: index < currentStep
                                ? AppColors.primary
                                : index == currentStep
                                ? AppColors.primaryLight
                                : AppColors.field,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index <= currentStep
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: index == currentStep ? 2 : 1,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                            child: index < currentStep
                                ? Icon(
                                    Icons.check_rounded,
                                    key: ValueKey('completed-$index'),
                                    size: 19,
                                    color: AppColors.textOnPrimary,
                                  )
                                : Text(
                                    '${index + 1}',
                                    key: ValueKey('step-$index'),
                                    style: AppTypography.labelMedium.copyWith(
                                      color: index == currentStep
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeInOutCubic,
                              height: 3,
                              decoration: BoxDecoration(
                                color: index < currentStep
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (var index = 0; index < steps.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onStepSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        steps[index],
                        textAlign: TextAlign.center,
                        style: (index == currentStep
                                ? AppTypography.labelMedium
                                : AppTypography.labelSmall)
                            .copyWith(
                              color: index == currentStep
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CourseFormStepActions extends StatelessWidget {
  const CourseFormStepActions({
    super.key,
    required this.onPrevious,
    required this.onNext,
    this.isLastStep = false,
    this.isFirstStep = false,
    this.isSubmitting = false,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isLastStep;
  final bool isFirstStep;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: isSubmitting ? null : onNext,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Text(isLastStep ? 'إنشاء الدورة' : 'التالي'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : onPrevious,
            child: Text(isFirstStep ? 'إلغاء' : 'السابق'),
          ),
        ),
      ],
    );
  }
}

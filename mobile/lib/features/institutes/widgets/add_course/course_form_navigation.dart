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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  steps[currentStep],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الخطوة ${currentStep + 1} من ${steps.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              for (var index = 0; index < steps.length; index++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == currentStep,
                    label: 'الانتقال إلى خطوة ${steps[index]}',
                    child: InkWell(
                      key: ValueKey('course-form-step-$index'),
                      onTap: () => onStepSelected(index),
                      child: SizedBox(
                        height: 28,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index < currentStep
                                  ? AppColors.primary
                                  : index == currentStep
                                  ? AppColors.accent
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
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
    this.lastStepLabel = 'إنشاء الدورة',
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isLastStep;
  final bool isFirstStep;
  final bool isSubmitting;
  final String lastStepLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : onPrevious,
            child: Text(isFirstStep ? 'إلغاء' : 'السابق'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

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
                : Text(isLastStep ? lastStepLabel : 'التالي'),
          ),
        ),
      ],
    );
  }
}

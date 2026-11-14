import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';

class CourseEnrollButton extends StatelessWidget {
  const CourseEnrollButton({
    super.key,
    required this.isFull,
    required this.onPressed,
  });

  final bool isFull;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isFull ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isFull ? 'الدورة مكتملة' : 'التسجيل في الدورة',
              style: AppTypography.titleMedium.copyWith(
                color: isFull
                    ? AppColors.textSecondary
                    : AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

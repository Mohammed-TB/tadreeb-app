import 'package:flutter/material.dart';
import 'package:project_1/app/theme/app_colors.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/button.dart';

abstract final class CourseActionConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(message, style: AppTypography.bodyMedium),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        text: 'إلغاء',
                        variant: AppButtonVariant.outline,
                        height: 40,
                        onTap: () => Navigator.pop(dialogContext, false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Button(
                        text: confirmText,
                        variant: AppButtonVariant.accent,
                        height: 40,
                        onTap: () => Navigator.pop(dialogContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }
}

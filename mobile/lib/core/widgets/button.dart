
import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  accent,
  secondary,
  outline,
  text,
}

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.text,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.width = double.infinity,
    this.height = 44,
    this.fontSize = 14,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    this.icon,
    this.iconPosition = IconAlignment.start,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.fontWeight = FontWeight.w700,
  });

  final String text;
  final VoidCallback? onTap;

  // نوع الزر
  final AppButtonVariant variant;

  // الأبعاد
  final double? width;
  final double height;

  // النص
  final double fontSize;
  final FontWeight fontWeight;

  // الشكل
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  // الأيقونة
  final IconData? icon;
  final IconAlignment iconPosition;

  // الحالات
  final bool isLoading;
  final bool isDisabled;

  // تخصيص الألوان
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  bool get _isDisabled =>
      isDisabled || isLoading || onTap == null;

  Color get _backgroundColor {
    if (backgroundColor != null) return backgroundColor!;

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;

      case AppButtonVariant.accent:
        return AppColors.accent;

      case AppButtonVariant.secondary:
        return AppColors.primaryLight;

      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    if (foregroundColor != null) return foregroundColor!;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.accent:
        return Colors.white;

      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }

  Color get _borderColor {
    if (borderColor != null) return borderColor!;

    switch (variant) {
      case AppButtonVariant.accent:
        return AppColors.accent;

      case AppButtonVariant.outline:
        return AppColors.border;

      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: _isDisabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: _foregroundColor,
          disabledBackgroundColor: AppColors.field,
          disabledForegroundColor: AppColors.textHint,
          padding: padding,
          side: BorderSide(
            color: _borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _foregroundColor,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      textDirection: Directionality.of(context),
      children: [
        if (icon != null && iconPosition == IconAlignment.start) ...[
          Icon(
            icon,
            size: fontSize + 4,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],

        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: _foregroundColor,
            ),
          ),
        ),

        if (icon != null && iconPosition == IconAlignment.end) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            icon,
            size: fontSize + 4,
          ),
        ],
      ],
    );
  }
}

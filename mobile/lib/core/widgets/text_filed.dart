
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class TextFieldApp extends StatelessWidget {
  const TextFieldApp({
    super.key,
    required this.hinText,
    required this.icon,
    this.controller,
    this.isBorder = true,
    this.height = 46,
    this.borderRadius = 12,
    this.fillColor,
    this.iconColor,
    this.isEnabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
  });

  final String hinText;
  final IconData icon;
  final TextEditingController? controller;

  // التصميم
  final bool isBorder;
  final double height;
  final double borderRadius;
  final Color? fillColor;
  final Color? iconColor;

  // التحكم
  final bool isEnabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final borderSide = isBorder
        ? const BorderSide(color: AppColors.border)
        : BorderSide.none;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: borderSide,
    );

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        enabled: isEnabled,
        textDirection: TextDirection.rtl,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hinText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),

          prefixIcon: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textSecondary,
          ),

          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),

          suffixIcon: suffixIcon,

          isDense: true,
          filled: true,
          fillColor: fillColor ?? AppColors.field,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),

          border: border,
          enabledBorder: border,

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),

          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

class CustomTextFiledForm extends StatelessWidget {
  const CustomTextFiledForm({
    super.key,
    required this.controller,
    required this.hinText,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.isBorder = true,
    this.isEnabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.borderRadius = 12,
    this.fillColor,
    this.iconColor,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hinText;
  final IconData icon;

  // التحقق والتحكم
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  // الخصائص المرئية
  final bool isBorder;
  final bool isEnabled;
  final bool readOnly;
  final int maxLines;
  final double borderRadius;
  final Color? fillColor;
  final Color? iconColor;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: isBorder
          ? const BorderSide(color: AppColors.border)
          : BorderSide.none,
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      enabled: isEnabled,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      textDirection: TextDirection.rtl,

      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),

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

        suffixIcon: suffixIcon,

        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),

        isDense: true,
        filled: true,
        fillColor: fillColor ?? AppColors.field,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
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

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

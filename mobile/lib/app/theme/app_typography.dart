

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

abstract final class AppTypography {
  static final TextStyle display = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineLarge = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineMedium = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineSmall = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleSmall = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  static final TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static final TextTheme textTheme = TextTheme(
    displayLarge: display,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
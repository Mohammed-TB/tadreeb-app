import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class AdminInstituteFormSection extends StatelessWidget {
  const AdminInstituteFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.description,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.titleSmall),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

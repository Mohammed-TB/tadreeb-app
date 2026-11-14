import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({
    super.key,
    required this.adminName,
    this.onMenuTap,
  });

  final String? adminName;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Builder(
                builder: (headerContext) => IconButton(
                  onPressed:
                      onMenuTap ??
                      () => Scaffold.of(headerContext).openDrawer(),
                  tooltip: 'القائمة',
                  color: AppColors.textOnPrimary,
                  icon: const Icon(Icons.menu),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName == null || adminName!.trim().isEmpty
                          ? 'إدارة المنصة'
                          : 'مرحباً، $adminName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'ملخص مؤشرات المنصة',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

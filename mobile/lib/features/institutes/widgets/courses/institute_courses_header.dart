import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_shell.dart';

class InstituteCoursesHeader extends StatelessWidget {
  const InstituteCoursesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final openShellDrawer = AppShellDrawerScope.maybeOf(context)?.openDrawer;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
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
                            IconButton(
                              onPressed:
                                  openShellDrawer ??
                                  () => Scaffold.of(context).openDrawer(),
                              tooltip: 'القائمة الرئيسية',
                              color: AppColors.textOnPrimary,
                              icon: const Icon(Icons.menu),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة الدورات التدريبية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
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

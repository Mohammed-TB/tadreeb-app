import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class InstituteStudentsScreen extends StatelessWidget {
  const InstituteStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (headerContext) => IconButton(
                      onPressed: () => Scaffold.of(headerContext).openDrawer(),
                      tooltip: 'فتح القائمة',
                      color: AppColors.textOnPrimary,
                      icon: const Icon(Icons.menu),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'الطلاب المسجلون',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_emptyState()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.groups_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'قائمة الطلاب',
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ستظهر هنا بيانات الطلاب المسجلين في دورات معهدك.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

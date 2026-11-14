import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class AdminInstituteLogoPicker extends StatelessWidget {
  const AdminInstituteLogoPicker({
    super.key,
    required this.imageBytes,
    required this.isPicking,
    required this.errorMessage,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final bool isPicking;
  final String? errorMessage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('شعار المعهد (اختياري)', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isPicking ? null : onPick,
            child: Container(
              height: 168,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: imageBytes == null ? _buildPlaceholder() : _buildPreview(),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            errorMessage!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          'JPG أو PNG أو WEBP • حتى 5 ميجابايت',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isPicking
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                )
              : Container(
                  key: const ValueKey('add-image'),
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isPicking ? 'جارٍ فتح الصور...' : 'اضغط لإضافة شعار المعهد',
          style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'اختر صورة من معرض الصور',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.field,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Image.memory(imageBytes!, fit: BoxFit.contain),
          ),
        ),
        PositionedDirectional(
          top: AppSpacing.xs,
          end: AppSpacing.xs,
          child: IconButton.filled(
            onPressed: isPicking ? null : onRemove,
            tooltip: 'إزالة الشعار',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.error,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
        PositionedDirectional(
          bottom: AppSpacing.xs,
          start: AppSpacing.xs,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('اضغط لتغيير الشعار', style: AppTypography.labelSmall),
          ),
        ),
      ],
    );
  }
}

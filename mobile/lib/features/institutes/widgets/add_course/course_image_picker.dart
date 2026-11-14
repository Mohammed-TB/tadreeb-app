import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// مكون اختيار ومعاينة صورة الدورة
class CourseImagePickerCard extends StatelessWidget {
  const CourseImagePickerCard({
    super.key,
    required this.imageBytes,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? imageBytes;
  final bool isPickingImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('صورة الدورة', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isPickingImage ? null : onPickImage,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: imageBytes == null
                  ? _buildPlaceholder()
                  : _buildPreview(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isPickingImage)
          const CircularProgressIndicator()
        else
          const Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            size: 38,
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isPickingImage ? 'جارٍ تجهيز الصورة...' : 'اضغط لإضافة صورة للدورة',
          style: AppTypography.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'JPG أو PNG أو WEBP • حتى 5 ميجابايت • اختياري',
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(imageBytes!, fit: BoxFit.cover),
        PositionedDirectional(
          top: AppSpacing.xs,
          end: AppSpacing.xs,
          child: IconButton.filled(
            onPressed: isPickingImage ? null : onRemoveImage,
            tooltip: 'إزالة الصورة',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.error,
            ),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        PositionedDirectional(
          bottom: AppSpacing.xs,
          end: AppSpacing.xs,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('تغيير الصورة', style: AppTypography.labelSmall),
          ),
        ),
      ],
    );
  }
}

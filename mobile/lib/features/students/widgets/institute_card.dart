
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../institutes/models/institute_model.dart';

class InstituteCard extends StatelessWidget {
  const InstituteCard({
    super.key,
    required this.institute,
    this.width = 200,
    this.imageHeight = 110,
    this.onTap,
    this.showDetailsButton = true,
    this.buttonText = 'عرض التفاصيل',
  });

  final InstituteModel institute;

  // الأبعاد
  final double width;
  final double imageHeight;

  // السلوك
  final VoidCallback? onTap;
  final bool showDetailsButton;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInstituteImage(),
          _buildInstituteDetails(),
        ],
      ),
    );
  }

  Widget _buildInstituteImage() {
    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: Image.asset(
        institute.instituteImageUrl ?? 'assets/images/institute1.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primaryLight,
            alignment: Alignment.center,
            child: const Icon(
              Icons.apartment_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstituteDetails() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            institute.instituteName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall,
          ),

          const SizedBox(height: AppSpacing.xs),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  institute.instituteAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),

          if (showDetailsButton) ...[
            const SizedBox(height: AppSpacing.sm),
            Button(
              text: buttonText,
              width: double.infinity,
              height: 38,
              fontSize: 12,
              variant: AppButtonVariant.primary,
              onTap: onTap,
            ),
          ],
        ],
      ),
    );
  }
}

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
    this.isFavorite = false,
    this.onFavoriteTap,
    this.isFavoriteBusy = false,
  });

  final InstituteModel institute;

  final double width;
  final double imageHeight;

  final VoidCallback? onTap;
  final bool showDetailsButton;
  final String buttonText;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool isFavoriteBusy;

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
          if (onFavoriteTap != null)
            PositionedDirectional(
              top: AppSpacing.xs,
              start: AppSpacing.xs,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(isFavorite),
                tween: Tween(begin: 0.55, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Material(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: isFavorite
                        ? 'إزالة من المفضلة'
                        : 'إضافة إلى المفضلة',
                    onPressed: isFavoriteBusy ? null : onFavoriteTap,
                    visualDensity: VisualDensity.compact,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        key: ValueKey(isFavorite),
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? AppColors.error
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final image = institute.imageUrl;
    final isNetworkImage =
        image != null &&
        (image.startsWith('http://') || image.startsWith('https://'));
    Widget errorWidget(BuildContext context, Object error, StackTrace? trace) {
      return Container(
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.apartment_outlined,
          color: AppColors.primary,
          size: 42,
        ),
      );
    }

    if (isNetworkImage) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: errorWidget,
      );
    }
    return Image.asset(
      image ?? 'assets/images/institute1.png',
      fit: BoxFit.cover,
      errorBuilder: errorWidget,
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
            institute.name,
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
                  institute.address,
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
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../institutes/models/institute_model.dart';

enum InstituteCardLayout { vertical, horizontal }

class InstituteCard extends StatelessWidget {
  const InstituteCard({
    super.key,
    required this.institute,
    this.width = 200,
    this.imageHeight = 110,
    this.layout = InstituteCardLayout.vertical,
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
  final InstituteCardLayout layout;

  final VoidCallback? onTap;
  final bool showDetailsButton;
  final String buttonText;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool isFavoriteBusy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          width: width,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
            color: AppColors.surface,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: layout == InstituteCardLayout.horizontal
                ? _buildHorizontalCard()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInstituteImage(),
                      _buildInstituteDetails(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard() {
    return SizedBox(
      
      height: imageHeight,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            width: imageHeight,
            height: imageHeight,
            child: _buildInstituteImage(),
          ),
          Expanded(child: _buildInstituteDetails(isHorizontal: true)),
          if (onFavoriteTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SizedBox(width: 48, child: Center(child: _buildFavoriteButton())),
            ),
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
          if (onFavoriteTap != null && layout == InstituteCardLayout.vertical)
            PositionedDirectional(
              top: AppSpacing.xs,
              start: AppSpacing.xs,
              child: _buildFavoriteButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(isFavorite),
      tween: Tween(begin: 0.55, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        child: InkWell(
            onTap: isFavoriteBusy ? null : onFavoriteTap,

          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border)
            ),
            child: IconButton(
              tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              onPressed: isFavoriteBusy ? null : onFavoriteTap,
              visualDensity: VisualDensity.compact,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  key: ValueKey(isFavorite),
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.error : AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final image = institute.imageUrl;

    final isNetworkImage =
        image != null &&
        (image.startsWith('http://') || image.startsWith('https://'));

    if (isNetworkImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildImagePlaceholder(),

          CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox.expand(),
            errorWidget: (context, url, error) => _buildPlaceholder(),
          ),
        ],
      );
    }

    if (image != null && image.isNotEmpty) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.surface,
            AppColors.primaryLight.withValues(alpha: 0.65),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary.withAlpha(5), AppColors.surface],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.account_balance_outlined,
        size: 42,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInstituteDetails({bool isHorizontal = false}) {
    return Padding(
      padding: EdgeInsets.all(isHorizontal ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isHorizontal
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            institute.name,
            maxLines: isHorizontal ? 2 : 1,
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
                  maxLines: isHorizontal ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),

          if (showDetailsButton) ...[
            SizedBox(height: isHorizontal ? AppSpacing.xs : AppSpacing.sm),
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

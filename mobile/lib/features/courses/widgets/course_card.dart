import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/widgets/button.dart';
import 'package:project_1/features/courses/models/course_model.dart';
// import 'package:provider/provider.dart';

// import '../../institutes/controllers/institute_controller.dart';
// import '../../institutes/models/institute_model.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.showDetailsCourse,
    this.isHorizontal = false,
    this.width,
    this.height,
    this.showDetailsButton = true,
    this.buttonText = 'عرض التفاصيل',
    this.isFavorite = false,
    this.onFavoriteTap,
    this.isFavoriteBusy = false,
  });

  final CourseModel course;
  final VoidCallback showDetailsCourse;

  // شكل البطاقة
  final bool isHorizontal;
  final double? width;
  final double? height;

  // زر التفاصيل
  final bool showDetailsButton;
  final String buttonText;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool isFavoriteBusy;

  // String _instituteName(List<InstituteModel> institutes) {
  //   for (final institute in institutes) {
  //     if (institute.id == course.instituteId) {
  //       return institute.name;
  //     }
  //   }

  //   return 'معهد غير معروف';
  // }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Container(
      width: width ?? (isHorizontal ? 320 : 200),
      margin: EdgeInsets.only(
        right: isHorizontal ? 0 : AppSpacing.xxs,
        bottom: isHorizontal ? 1 : 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: isHorizontal
            ? _buildHorizontalCard(course.category)
            : _buildVerticalCard(course.category),
      ),
    );
  }

  Widget _buildCourseImage() {
    final image = course.image;
    final isNetworkImage =
        image != null &&
        (image.startsWith('http://') || image.startsWith('https://'));
    Widget errorWidget(BuildContext context, Object error, StackTrace? trace) {
      return Container(
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.school_outlined,
          size: 40,
          color: AppColors.primary,
        ),
      );
    }

    if (isNetworkImage) {
      return Image.network(image, fit: BoxFit.cover, errorBuilder: errorWidget);
    }

    return Image.asset(
      image ?? 'assets/images/english2_course.png',
      fit: BoxFit.cover,
      errorBuilder: errorWidget,
    );
  }

  // البطاقة العمودية
  Widget _buildVerticalCard(String instituteName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height ?? 110,
          width: double.infinity,
          child: _buildImage(),
        ),
        _buildDetails(instituteName),
      ],
    );
  }

  // البطاقة الأفقية

  Widget _buildHorizontalCard(String instituteName) {
    return SizedBox(
      height: height ?? 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _buildImage()),
          Expanded(flex: 3, child: _buildDetails(instituteName)),
        ],
      ),
    );
  }

  // صورة الدورة
  Widget _buildImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isRTL = Directionality.of(context) == TextDirection.rtl;

        return ClipRRect(
          borderRadius: isHorizontal
              ? BorderRadius.horizontal(
            right: isRTL ? const Radius.circular(12) : Radius.zero,
            left: isRTL ? Radius.zero : const Radius.circular(12),
          )
              : const BorderRadius.vertical(top: Radius.circular(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCourseImage(),

              PositionedDirectional(
                top: AppSpacing.xs,
                end: AppSpacing.xs,
                child: _buildStatusBadge(),
              ),
              if (onFavoriteTap != null)
                PositionedDirectional(
                  top: AppSpacing.xs,
                  start: AppSpacing.xs,
                  child: _buildFavoriteButton(),
                ),
            ],
          ),
        );
      },
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
    );
  }

  // حالة الدورة
  Widget _buildStatusBadge() {
    final isFull = course.isFull == true;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isFull ? AppColors.errorLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFull ? 'مكتمل' : 'متاح',
        style: AppTypography.labelSmall.copyWith(
          color: isFull ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }

  // تفاصيل الدورة

  Widget _buildDetails(String instituteName) {
    return Padding(
      padding: EdgeInsets.all(isHorizontal ? AppSpacing.xs : AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isHorizontal
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // اسم الدورة
          Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.start,
            style: AppTypography.titleSmall,
          ),

          // اسم المعهد
          Text(
            instituteName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.start,
            style: AppTypography.bodySmall,
          ),

          // المقاعد
          Text(
            'المقاعد: ${course.enrolledCount + course.reservedCount} / ${course.capacity}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
          SizedBox(height: AppSpacing.xxs),

          // السعر والزر
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${course.price} ريال',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (showDetailsButton) ...[
                const SizedBox(height: AppSpacing.sm),
                Button(
                  text: buttonText,
                  width: double.infinity,
                  height: 36,
                  fontSize: 12,
                  variant: AppButtonVariant.primary,
                  onTap: showDetailsCourse,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

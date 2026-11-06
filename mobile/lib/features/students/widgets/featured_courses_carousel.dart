
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/widgets/button.dart';

import '../../courses/models/course_model.dart';

class FeaturedCoursesCarousel extends StatelessWidget {
  const FeaturedCoursesCarousel({
    super.key,
    required this.courses,
    this.onExploreTap,
    this.height = 160,
    this.autoPlay = true,
  });

  final List<CourseModel> courses;
  final VoidCallback? onExploreTap;
  final double height;
  final bool autoPlay;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider.builder(
      itemCount: courses.length,

      itemBuilder: (context, index, realIndex) {
        final course = courses[index];

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,

          child: Stack(
            fit: StackFit.expand,
            children: [
              // خلفية البطاقة
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.school_outlined,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),

              // محتوى البطاقة
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.md,
                left: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // زر استكشاف الدورات
              Positioned(
                bottom: AppSpacing.sm,
                right: AppSpacing.md,
                child: Button(
                  text: 'استكشف الدورات',
                  width: 130,
                  height: 34,
                  fontSize: 12,
                  variant: AppButtonVariant.secondary,
                  onTap: onExploreTap,
                ),
              ),
            ],
          ),
        );
      },

      options: CarouselOptions(
        height: height,
        autoPlay: autoPlay && courses.length > 1,
        enlargeCenterPage: true,
        viewportFraction: 0.88,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enableInfiniteScroll: courses.length > 1,
      ),
    );
  }
}

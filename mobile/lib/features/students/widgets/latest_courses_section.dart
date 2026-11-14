import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../courses/models/course_model.dart';
import '../../courses/widgets/course_card.dart';
import '../../favorites/controllers/favorite_controller.dart';

class LatestCoursesSection extends StatelessWidget {
  const LatestCoursesSection({
    super.key,
    required this.courses,
    required this.favorites,
    required this.onShowDetails,
    required this.onSeeAll,
  });

  final List<CourseModel> courses;
  final FavoriteController favorites;
  final ValueChanged<CourseModel> onShowDetails;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final latestCourses = List<CourseModel>.from(courses)
      ..sort((a, b) {
        final dateA = a.createdAt ?? a.startDate;
        final dateB = b.createdAt ?? b.startDate;
        return dateB.compareTo(dateA);
      });
    final previewCourses = latestCourses.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.new_releases_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text('أحدث الدورات المضافة', style: AppTypography.titleMedium),
                ],
              ),
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عرض الكل',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: previewCourses.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.cardGap),
            itemBuilder: (context, index) {
              final course = previewCourses[index];
              return CourseCard(
                course: course,
                isHorizontal: true,
                showDetailsCourse: () => onShowDetails(course),
                isFavorite: favorites.isCourseFavorite(course.id),
                isFavoriteBusy: favorites.isCourseSaving(course.id),
                onFavoriteTap: favorites.canToggleFavorites
                    ? () => favorites.toggleCourse(course)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

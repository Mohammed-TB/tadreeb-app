import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:project_1/features/institutes/controllers/institute_controller.dart';
import 'package:project_1/features/institutes/models/institute_model.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_skeletons.dart';

import '../../courses/controllers/course_controller.dart';
import '../../courses/models/course_model.dart';
import '../../courses/widgets/course_card.dart';
import '../../favorites/controllers/favorite_controller.dart';

class MostPopularCourses extends StatefulWidget {
  const MostPopularCourses({super.key, required this.showDetailsCourse});

  final ValueChanged<CourseModel> showDetailsCourse;

  @override
  State<MostPopularCourses> createState() => _MostPopularCoursesState();
}

class _MostPopularCoursesState extends State<MostPopularCourses> {
  // الانتقال إلى صفحة جميع الدورات
  void _showCourses() {
    context.go('/courses_screen');
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseController>();
    final favorites = context.watch<FavoriteController>();

    final institutes = context.watch<InstituteController>().institutes;

    final featured = courses.featuredCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),

        const SizedBox(height: AppSpacing.sm),

        _buildCoursesContent(courses, favorites, featured, institutes),
      ],
    );
  }

  // عنوان القسم
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الدورات الأكثر رواجاً', style: AppTypography.titleMedium),
          InkWell(
            onTap: _showCourses,
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
    );
  }

  // محتوى الدورات
  Widget _buildCoursesContent(
    CourseController controller,
    FavoriteController favorites,
    List<CourseModel> courses,
    List<InstituteModel> institutes,
  ) {
    if (controller.isLoading && courses.isEmpty) {
      return const AppSkeletonList(
        itemCount: 1,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        leadingSize: 104,
        textLines: 2,
      );
    }

    if (courses.isEmpty && controller.errorMessage != null) {
      return _buildMessage(
        'تعذر تحميل الدورات',
        icon: Icons.error_outline,
        action: TextButton.icon(
          onPressed: () => controller.getCourses(forceRefresh: true),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );
    }

    if (courses.isEmpty) {
      return _buildMessage(
        'لا توجد دورات متاحة حالياً',
        icon: Icons.school_outlined,
      );
    }

    return _buildCoursesList(courses, favorites, institutes);
  }

  // قائمة الدورات الأفقية
  Widget _buildCoursesList(
    List<CourseModel> courses,
    FavoriteController favorites,
    List<InstituteModel> institutes,
  ) {
    return SizedBox(
      height: 275,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: courses.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.xs);
        },
        itemBuilder: (context, index) {
          final course = courses[index];

          return CourseCard(
            course: course,
            institutes: institutes,
            isHorizontal: false,
            showDetailsCourse: () {
              widget.showDetailsCourse(course);
            },
            isFavorite: favorites.isCourseFavorite(course.id),
            isFavoriteBusy: favorites.isCourseSaving(course.id),
            onFavoriteTap: favorites.canToggleFavorites
                ? () => _toggleFavorite(course)
                : null,
          );
        },
      ),
    );
  }

  // تحديث المفضلة
  Future<void> _toggleFavorite(CourseModel course) async {
    try {
      await context.read<FavoriteController>().toggleCourse(course);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('تعذر تحديث المفضلة: $error')));
    }
  }

  // رسائل التحميل والخطأ والفراغ
  Widget _buildMessage(
    String message, {
    required IconData icon,
    Widget? action,
  }) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: AppTypography.bodyMedium),
            ?action,
          ],
        ),
      ),
    );
  }
}

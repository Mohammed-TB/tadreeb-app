import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/core/widgets/search.dart';
import 'package:project_1/features/courses/controllers/course_controller.dart';
import 'package:project_1/features/favorites/controllers/favorite_controller.dart';
import 'package:project_1/features/students/widgets/list_category.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../models/course_model.dart';
import '../../widgets/course_card.dart';
import '../../widgets/course_filter_sheet.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseController>().getCourses();
      context.read<FavoriteController>().loadFavorites();
    });
  }

  void _showDetailsCourse(CourseModel course) {
    context.push('/courses_screen/details', extra: course);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CourseController>();
    final favorites = context.watch<FavoriteController>();
    final courses = controller.filteredCourses;

    return Column(
      children: [
        // Page header
        Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'الدورات',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    child: Builder(
                      builder: (headerContext) => IconButton(
                        onPressed: () =>
                            Scaffold.of(headerContext).openDrawer(),
                        tooltip: 'فتح القائمة',
                        icon: const Icon(Icons.menu, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Page content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Search(
                    hinText: 'ابحث عن دورة',
                    onChanged: controller.setSearchQuery,
                    controller: _searchController,
                    hasActiveFilter: controller.hasActiveFilter,
                    onFilterTap: () => CourseFilterSheet.show(context),
                  ),
                ),

                if (controller.hasActiveFilter)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'مرتب حسب: ${controller.sortOption.label}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => controller.resetSortOption(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ListCategory(
                    categories: controller.availableCategories,
                    selectedCategory:
                        controller.selectedCategory ?? 'الكل',
                    onCategorySelected: controller.selectCategory,
                  ),
                ),

                const SizedBox(height: 10),

                if (controller.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (courses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        controller.courses.isEmpty
                            ? 'لا توجد دورات متاحة حالياً'
                            : 'لا توجد نتائج مطابقة للبحث أو التصنيف',
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.cardGap),
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        return CourseCard(
                          course: course,
                          isHorizontal: true,
                          showDetailsCourse: () => _showDetailsCourse(course),
                          isFavorite: favorites.isCourseFavorite(course.id),
                          isFavoriteBusy: favorites.isCourseSaving(course.id),
                          onFavoriteTap: favorites.canToggleFavorites
                              ? () => _toggleFavorite(course)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

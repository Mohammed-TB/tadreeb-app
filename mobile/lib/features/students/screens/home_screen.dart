import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_1/core/mock_data/institutes_data.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/widgets/button.dart';
import 'package:project_1/features/students/widgets/header_home.dart';
import 'package:project_1/features/students/widgets/list_category.dart';
import 'package:project_1/features/students/widgets/most_popular_courses.dart';
import 'package:project_1/features/students/widgets/most_popular_institutes.dart';
import 'package:project_1/features/students/widgets/home_hero_banner.dart';
import 'package:project_1/features/students/widgets/latest_courses_section.dart';
import 'package:project_1/features/students/widgets/why_choose_us_section.dart';

import '../../courses/controllers/course_controller.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../../courses/models/course_model.dart';
import '../../courses/widgets/course_card.dart';
import '../../courses/widgets/course_filter_sheet.dart';
import '../../favorites/controllers/favorite_controller.dart';
import '../../institutes/controllers/institute_controller.dart';
import '../../institutes/models/institute_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadInitialData());
    });
  }

  Future<void> _loadInitialData() async {
    final courseController = context.read<CourseController>();
    final instituteController = context.read<InstituteController>();
    final favoriteController = context.read<FavoriteController>();

    unawaited(context.read<ReservationController>().fetchMyReservations());
    unawaited(favoriteController.loadFavorites());

    var initialContentShown = false;
    try {
      var hasCachedPublicData = false;
      try {
        final cachedData = await Future.wait([
          courseController.loadCachedCourses(),
          instituteController.loadCachedInstitutes(),
        ]);
        hasCachedPublicData = cachedData.any((hasCache) => hasCache);
      } catch (error) {
        debugPrint('Unable to read public startup cache: $error');
      }

      if (hasCachedPublicData && mounted) {
        setState(() => _isInitialLoading = false);
        initialContentShown = true;
      }

      final refresh = _refreshPublicData(courseController, instituteController);
      if (initialContentShown) {
        unawaited(refresh);
      } else {
        await refresh;
      }
    } finally {
      if (mounted && !initialContentShown) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _refreshPublicData(
    CourseController courseController,
    InstituteController instituteController,
  ) async {
    await Future.wait([
      courseController.getCourses(forceRefresh: true),
      instituteController.getInstitutes(forceRefresh: true),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<CourseController>().getCourses(forceRefresh: true),
      context.read<InstituteController>().getInstitutes(forceRefresh: true),
      context.read<ReservationController>().fetchMyReservations(
        forceRefresh: true,
      ),
      context.read<FavoriteController>().loadFavorites(forceRefresh: true),
    ]);
  }

  void _showDetailsCourse(CourseModel course) {
    context.push('/courses_screen/details', extra: course);
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  void _openFilterMenu() {
    CourseFilterSheet.show(context);
  }

  void _handleSearchSubmit(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      context.read<CourseController>().setSearchQuery(trimmed);
      context.go('/courses_screen');
    }
  }

  void _showInstituteDetails(InstituteModel institute) {
    context.push('/institute-details', extra: institute);
  }

  @override
  Widget build(BuildContext context) {
    final courseController = context.watch<CourseController>();
    final favoriteController = context.watch<FavoriteController>();
    final isSearching = _searchController.text.trim().isNotEmpty;

    if (_isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ترويسة الصفحة مع البحث المفعل
            HeaderHome(
              onMenuTap: _openDrawer,
              onFilterTap: _openFilterMenu,
              onSearchChanged: (value) {
                courseController.setSearchQuery(value);
                setState(() {});
              },
              onSearchSubmitted: _handleSearchSubmit,
              onClear: () {
                courseController.setSearchQuery('');
                setState(() {});
              },
              searchController: _searchController,
              hasActiveFilter: courseController.hasActiveFilter,
            ),

            // 2. إذا كان المستخدم يبحث في شريط البحث بالأعلى
            if (isSearching)
              _buildInstantSearchResults(courseController, favoriteController)
            else
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // 3. البانر الترويجي التفاعلي
                      HomeHeroBanner(
                        onExploreTap: () => context.go('/courses_screen'),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 5. التصنيفات
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListCategory(
                          categories: courseController.availableCategories,
                          selectedCategory:
                              courseController.selectedCategory ?? 'الكل',
                          onCategorySelected: courseController.selectCategory,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // 7. الدورات الأكثر رواجاً
                      MostPopularCourses(showDetailsCourse: _showDetailsCourse),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // 7. المعاهد الأكثر رواجاً
                      MostPopularInstitutes(
                        onSeeAll: () {
                          context.go('/institutes_screen');
                        },
                        onInstituteTap: _showInstituteDetails,
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // 8. أحدث الدورات المضافة
                      LatestCoursesSection(
                        courses: courseController.courses,
                        favorites: favoriteController,
                        onShowDetails: _showDetailsCourse,
                        onSeeAll: () {
                          courseController.setSortOption(
                            CourseSortOption.dateNewest,
                          );
                          context.go('/courses_screen');
                        },
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // 9. مميزات منصة تدريب
                      const WhyChooseUsSection(),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // نتائج البحث الفورية في الصفحة الرئيسية
  Widget _buildInstantSearchResults(
    CourseController controller,
    FavoriteController favorites,
  ) {
    final query = _searchController.text.trim();
    final results = controller.filteredCourses;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نتائج البحث عن "$query"',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${results.length} دورة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (results.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لم يتم العثور على نتائج تطابق "$query"',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جرّب كتابة كلمات بحث أخرى أو تصفح التصنيفات الشائعة',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length > 5 ? 5 : results.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, index) {
                final course = results[index];
                return CourseCard(
                  course: course,
                  institutes: institutes,
                  isHorizontal: true,
                  showDetailsCourse: () => _showDetailsCourse(course),
                  isFavorite: favorites.isCourseFavorite(course.id),
                  isFavoriteBusy: favorites.isCourseSaving(course.id),
                  onFavoriteTap: favorites.canToggleFavorites
                      ? () => favorites.toggleCourse(course)
                      : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Button(
              text: 'عرض جميع النتائج في صفحة الدورات (${results.length})',
              icon: Icons.open_in_new_rounded,
              height: 46,
              borderRadius: 12,
              onTap: () {
                context.go('/courses_screen');
              },
            ),
          ],
        ],
      ),
    );
  }
}

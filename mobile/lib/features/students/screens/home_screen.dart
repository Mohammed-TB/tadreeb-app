import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/widgets/button.dart';
import 'package:project_1/features/students/widgets/header_home.dart';
import 'package:project_1/features/students/widgets/list_category.dart';
import 'package:project_1/features/students/widgets/most_popular_courses.dart';
import 'package:project_1/features/students/widgets/most_popular_institutes.dart';
import 'package:project_1/features/students/widgets/active_reservations_reminder.dart';
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseController>().getCourses();
      context.read<InstituteController>().getInstitutes();
      context.read<ReservationController>().fetchMyReservations();
      context.read<FavoriteController>().loadFavorites();
    });
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
      context.read<InstituteController>().getInstitutes(),
      context.read<ReservationController>().fetchMyReservations(),
      context.read<FavoriteController>().loadFavorites(),
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

  void _showInstituteDetailsSheet(InstituteModel institute) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final logo = institute.imageUrl;
        final hasValidImage = logo != null &&
            (logo.startsWith('http://') || logo.startsWith('https://'));

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),

                // الشعار والاسم
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasValidImage
                          ? Image.network(
                              logo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.apartment_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            )
                          : const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  institute.name,
                                  style: AppTypography.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'معهد تدريبي معتمد',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),

                // العنوان
                if (institute.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            institute.address,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // رقم الهاتف
                if (institute.phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            institute.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // زر استعراض دورات المعهد
                Button(
                  text: 'استعراض دورات المعهد',
                  icon: Icons.school_outlined,
                  height: 46,
                  borderRadius: 12,
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    context
                        .read<CourseController>()
                        .setSearchQuery(institute.name);
                    context.go('/courses_screen');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseController = context.watch<CourseController>();
    final reservationController = context.watch<ReservationController>();
    final favoriteController = context.watch<FavoriteController>();
    final isSearching = _searchController.text.trim().isNotEmpty;

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

                      // 4. بطاقة تذكير الحجوزات النشطة
                      ActiveReservationsReminder(
                        activeCount: reservationController.pendingPaymentCount +
                            reservationController.underReviewCount,
                        onViewReservations: () =>
                            context.go('/my_reservations'),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 5. التصنيفات
                      ListCategory(
                        categories: courseController.availableCategories,
                        selectedCategory:
                            courseController.selectedCategory ?? 'الكل',
                        onCategorySelected: courseController.selectCategory,
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
                        onInstituteTap: _showInstituteDetailsSheet,
                      ),

                      const SizedBox(height: AppSpacing.sectionGap),

                      // 8. أحدث الدورات المضافة
                      LatestCoursesSection(
                        courses: courseController.courses,
                        favorites: favoriteController,
                        onShowDetails: _showDetailsCourse,
                        onSeeAll: () {
                          courseController
                              .setSortOption(CourseSortOption.dateNewest);
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

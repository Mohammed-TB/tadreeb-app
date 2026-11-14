import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../courses/models/course_model.dart';
import '../../courses/widgets/course_card.dart';
import '../../institutes/models/institute_model.dart';
import '../../students/widgets/institute_card.dart';
import '../controllers/favorite_controller.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteController>().loadFavorites();
    });
  }

  Future<void> _toggleCourse(CourseModel course) async {
    try {
      await context.read<FavoriteController>().toggleCourse(course);
    } catch (error) {
      if (mounted) _showMessage('تعذر تحديث المفضلة: $error');
    }
  }

  Future<void> _toggleInstitute(InstituteModel institute) async {
    try {
      await context.read<FavoriteController>().toggleInstitute(institute);
    } catch (error) {
      if (mounted) _showMessage('تعذر تحديث المفضلة: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('المفضلة', style: AppTypography.titleLarge),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          bottom: TabBar(
            labelStyle: AppTypography.labelMedium,
            tabs: [
              Tab(text: 'الدورات (${favorites.courses.length})'),
              Tab(text: 'المعاهد (${favorites.institutes.length})'),
            ],
          ),
        ),
        body: favorites.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : favorites.errorMessage != null
            ? _buildError(favorites)
            : TabBarView(
                children: [
                  _buildCourses(favorites),
                  _buildInstitutes(favorites),
                ],
              ),
      ),
    );
  }

  Widget _buildCourses(FavoriteController favorites) {
    if (favorites.courses.isEmpty) {
      return _buildEmpty('لا توجد دورات مفضلة', Icons.school_outlined);
    }

    return RefreshIndicator(
      onRefresh: () => favorites.loadFavorites(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: favorites.courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final course = favorites.courses[index];
          return CourseCard(
            course: course,
            isHorizontal: true,
            width: double.infinity,
            height: 170,
            showDetailsCourse: () =>
                context.push('/courses_screen/details', extra: course),
            isFavorite: true,
            isFavoriteBusy: favorites.isCourseSaving(course.id),
            onFavoriteTap: () => _toggleCourse(course),
          );
        },
      ),
    );
  }

  Widget _buildInstitutes(FavoriteController favorites) {
    if (favorites.institutes.isEmpty) {
      return _buildEmpty('لا توجد معاهد مفضلة', Icons.apartment_outlined);
    }

    return RefreshIndicator(
      onRefresh: () => favorites.loadFavorites(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: favorites.institutes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final institute = favorites.institutes[index];
          return InstituteCard(
            institute: institute,
            width: double.infinity,
            imageHeight: 150,
            showDetailsButton: false,
            isFavorite: true,
            isFavoriteBusy: favorites.isInstituteSaving(institute.id),
            onFavoriteTap: () => _toggleInstitute(institute),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildError(FavoriteController favorites) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'تعذر تحميل المفضلة',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              favorites.errorMessage!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () =>
                  favorites.loadFavorites(forceRefresh: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_skeletons.dart';

import '../../institutes/controllers/institute_controller.dart';
import '../../institutes/models/institute_model.dart';
import '../../favorites/controllers/favorite_controller.dart';
import '../../students/widgets/institute_card.dart';

class MostPopularInstitutes extends StatelessWidget {
  const MostPopularInstitutes({super.key, this.onSeeAll, this.onInstituteTap});

  final VoidCallback? onSeeAll;
  final ValueChanged<InstituteModel>? onInstituteTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InstituteController>();
    final favorites = context.watch<FavoriteController>();
    final institutes = controller.institutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),

        const SizedBox(height: AppSpacing.sm),

        if (controller.isLoading && institutes.isEmpty)
          const AppSkeletonList(
            itemCount: 1,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            leadingSize: 72,
            circularLeading: true,
            textLines: 2,
          )
        else if (institutes.isEmpty && controller.errorMessage != null)
          _buildError(context)
        else if (institutes.isEmpty)
          _buildEmptyMessage()
        else
          _buildInstitutesList(context, institutes, favorites),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: TextButton.icon(
          onPressed: () => context.read<InstituteController>().getInstitutes(
            forceRefresh: true,
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تعذر تحميل المعاهد، أعد المحاولة'),
        ),
      ),
    );
  }

  // عنوان القسم
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('معاهد مميزة', style: AppTypography.titleMedium),

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
    );
  }

  // قائمة المعاهد
  Widget _buildInstitutesList(
    BuildContext context,
    List<InstituteModel> institutes,
    FavoriteController favorites,
  ) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        itemCount: institutes.length,

        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.sm);
        },

        itemBuilder: (context, index) {
          final institute = institutes[index];

          return InstituteCard(
            institute: institute,
            width: 200,
            imageHeight: 110,
            onTap: () => onInstituteTap?.call(institute),
            isFavorite: favorites.isInstituteFavorite(institute.id),
            isFavoriteBusy: favorites.isInstituteSaving(institute.id),
            onFavoriteTap: favorites.canToggleFavorites
                ? () => _toggleFavorite(context, institute)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    InstituteModel institute,
  ) async {
    try {
      await context.read<FavoriteController>().toggleInstitute(institute);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('تعذر تحديث المفضلة: $error')));
    }
  }

  // حالة القائمة الفارغة
  Widget _buildEmptyMessage() {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.apartment_outlined,
              size: 36,
              color: AppColors.textHint,
            ),

            const SizedBox(height: AppSpacing.xs),

            Text('لا توجد معاهد متاحة حالياً', style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}

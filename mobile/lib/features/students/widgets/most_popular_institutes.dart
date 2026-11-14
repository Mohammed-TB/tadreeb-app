
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

import '../../institutes/controllers/institute_controller.dart';
import '../../institutes/models/institute_model.dart';
import '../../students/widgets/institute_card.dart';

class MostPopularInstitutes extends StatefulWidget {
  const MostPopularInstitutes({
    super.key,
    this.onSeeAll,
    this.onInstituteTap,
  });

  final VoidCallback? onSeeAll;
  final ValueChanged<InstituteModel>? onInstituteTap;

  @override
  State<MostPopularInstitutes> createState() =>
      _MostPopularInstitutesState();
}

class _MostPopularInstitutesState
    extends State<MostPopularInstitutes> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<InstituteController>().getInstitutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InstituteController>();
    final institutes = controller.institutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),

        const SizedBox(height: AppSpacing.sm),

        if (controller.isLoading)
          const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (institutes.isEmpty)
          _buildEmptyMessage()
        else
          _buildInstitutesList(institutes),
      ],
    );
  }

  // عنوان القسم
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'معاهد مميزة',
            style: AppTypography.titleMedium,
          ),

          InkWell(
            onTap: widget.onSeeAll,
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
  Widget _buildInstitutesList(List<InstituteModel> institutes) {
    return SizedBox(
      height: 255,
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
            onTap: () {
              widget.onInstituteTap?.call(institute);
            },
          );
        },
      ),
    );
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

            Text(
              'لا توجد معاهد متاحة حالياً',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

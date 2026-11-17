import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/search.dart';
import '../../../courses/models/course_model.dart';

class InstituteCoursesFilterSection extends StatelessWidget {
  const InstituteCoursesFilterSection({
    super.key,
    required this.searchController,
    required this.filters,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final List<(String, CourseStatus?)> filters;
  final CourseStatus? selectedStatus;
  final ValueChanged<CourseStatus?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Search(
          controller: searchController,
          hinText: 'ابحث باسم الدورة أو التصنيف...',
          isShowFilter: false,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: filters.map((filter) {
              final isSelected = selectedStatus == filter.$2;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(filter.$1),
                  selected: isSelected,
                  onSelected: (_) => onStatusChanged(filter.$2),
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.2 : 1,
                  ),
                  labelStyle: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

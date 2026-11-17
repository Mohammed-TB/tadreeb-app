import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/button.dart';
import '../../../courses/models/course_model.dart';
import '../state_panel.dart';
import 'institute_course_card.dart';

class InstituteCoursesListSection extends StatelessWidget {
  const InstituteCoursesListSection({
    super.key,
    required this.courses,
    required this.isLoading,
    required this.errorMessage,
    required this.hasActiveFilters,
    required this.onRetry,
    required this.onClearFilters,
    required this.onAddCourse,
    required this.onEditCourse,
    required this.onPublishCourse,
    required this.onCloseCourse,
    required this.onReopenCourse,
    required this.onDeleteCourse,
  });

  final List<CourseModel> courses;
  final bool isLoading;
  final String? errorMessage;
  final bool hasActiveFilters;
  final VoidCallback onRetry;
  final VoidCallback onClearFilters;
  final VoidCallback onAddCourse;
  final ValueChanged<CourseModel> onEditCourse;
  final ValueChanged<CourseModel> onPublishCourse;
  final ValueChanged<CourseModel> onCloseCourse;
  final ValueChanged<CourseModel> onReopenCourse;
  final ValueChanged<CourseModel> onDeleteCourse;

  @override
  Widget build(BuildContext context) {
    if (isLoading && courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null && courses.isEmpty) {
      return StatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'تعذر تحميل الدورات',
        message: errorMessage!,
        action: Button(
          text: 'إعادة المحاولة',
          variant: AppButtonVariant.accent,
          icon: Icons.refresh_rounded,
          width: 160,
          height: 40,
          onTap: onRetry,
        ),
      );
    }

    if (courses.isEmpty) {
      return StatePanel(
        icon: hasActiveFilters
            ? Icons.search_off_rounded
            : Icons.school_outlined,
        title: hasActiveFilters
            ? 'لا توجد نتائج مطابقة'
            : 'لم تقم بإضافة أي دورة بعد',
        message: hasActiveFilters
            ? 'جرّب تغيير كلمات البحث أو اختيار حالة أخرى.'
            : 'ابدأ بإضافة أول برنامج تدريبي لمعهدك واستقبل تسجيلات الطلاب فوراً.',
        action: Button(
          text: hasActiveFilters ? 'إلغاء الفلترة' : 'إضافة دورة جديدة',
          variant: hasActiveFilters
              ? AppButtonVariant.outline
              : AppButtonVariant.accent,
          icon: hasActiveFilters ? null : Icons.add_rounded,
          width: hasActiveFilters ? 140 : 170,
          height: hasActiveFilters ? 38 : 42,
          onTap: hasActiveFilters ? onClearFilters : onAddCourse,
        ),
      );
    }

    return Column(
      children: [
        ...courses.map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InstituteCourseCard(
              course: course,
              onEdit: course.status == CourseStatus.draft
                  ? () => onEditCourse(course)
                  : null,
              onPublish: () => onPublishCourse(course),
              onClose: () => onCloseCourse(course),
              onReopen: () => onReopenCourse(course),
              onDelete: () => onDeleteCourse(course),
            ),
          ),
        ),
      ],
    );
  }
}

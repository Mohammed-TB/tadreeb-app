import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../courses/models/course_model.dart';

/// بطاقة دورة تفاعلية أنيقة متطابقة مع نظام تصميم لوحة تحكم المعهد
class InstituteCourseCard extends StatelessWidget {
  const InstituteCourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onPublish,
    this.onClose,
    this.onDelete,
  });

  final CourseModel course;
  final VoidCallback? onTap;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (course.status) {
      CourseStatus.draft => AppColors.warning,
      CourseStatus.published => AppColors.success,
      CourseStatus.closed => AppColors.error,
      CourseStatus.completed => AppColors.primary,
    };

    final statusBackground = switch (course.status) {
      CourseStatus.draft => AppColors.warningLight,
      CourseStatus.published => AppColors.successLight,
      CourseStatus.closed => AppColors.errorLight,
      CourseStatus.completed => AppColors.primaryLight,
    };

    final capacity = course.capacity > 0 ? course.capacity : 1;
    final occupancyRatio = (course.enrolledCount / capacity).clamp(0.0, 1.0);
    final hasActions = (course.status == CourseStatus.draft &&
            (onPublish != null || onDelete != null)) ||
        (course.status == CourseStatus.published && onClose != null);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. رأس البطاقة (صورة الدورة، شارة الحالة، شارة التصنيف، وقائمة الخيارات)
              SizedBox(
                height: 145,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCourseImage(course.image),
                    // تدرج ظلي خفيف لضمان وضوح الشارات
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                            Colors.black45,
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    // شارة الحالة
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              _statusLabel(course.status),
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // شارة التصنيف
                    PositionedDirectional(
                      bottom: AppSpacing.sm,
                      end: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          course.category,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // قائمة الإجراءات
                    if (hasActions)
                      PositionedDirectional(
                        top: AppSpacing.xs,
                        end: AppSpacing.xs,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            tooltip: 'خيارات الدورة',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) {
                              if (value == 'publish') onPublish?.call();
                              if (value == 'close') onClose?.call();
                              if (value == 'delete') onDelete?.call();
                            },
                            itemBuilder: (context) => [
                              if (course.status == CourseStatus.draft &&
                                  onPublish != null)
                                const PopupMenuItem(
                                  value: 'publish',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Text('نشر الدورة الآن'),
                                    ],
                                  ),
                                ),
                              if (course.status == CourseStatus.published &&
                                  onClose != null)
                                const PopupMenuItem(
                                  value: 'close',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.block_outlined,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Text('إغلاق التسجيل'),
                                    ],
                                  ),
                                ),
                              if (course.status == CourseStatus.draft &&
                                  onDelete != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'حذف المسودة',
                                        style: TextStyle(color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. محتوى تفاصيل الدورة
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان الرئيسي للدورة
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // التواريخ والمكان
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            '${_formatDate(course.startDate)} - ${_formatDate(course.endDate)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (course.location.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              course.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),

                    // شريط نسبة الإشغال (نفس أسلوب لوحة التحكم)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'نسبة إشغال المقاعد',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${course.enrolledCount} / ${course.capacity} مسجل (${(occupancyRatio * 100).toInt()}%)',
                              style: AppTypography.labelSmall.copyWith(
                                color: occupancyRatio >= 1.0
                                    ? AppColors.error
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: occupancyRatio,
                            minHeight: 6,
                            backgroundColor: AppColors.primaryLight,
                            valueColor: AlwaysStoppedAnimation(
                              occupancyRatio >= 1.0
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.sm),

                    // الصف السفلي: السعر والعربون + زر الإجراء السريع المباشر
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${course.price.toStringAsFixed(0)} ر.ي',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (course.depositAmount > 0)
                              Text(
                                'العربون: ${course.depositAmount.toStringAsFixed(0)} ر.ي',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),

                        // زر الإجراء السريع بحسب الحالة
                        if (course.status == CourseStatus.draft && onPublish != null)
                          FilledButton.tonalIcon(
                            onPressed: onPublish,
                            icon: const Icon(Icons.publish_rounded, size: 16),
                            label: const Text('نشر الدورة'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.successLight,
                              foregroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else if (course.status == CourseStatus.published &&
                            onClose != null)
                          OutlinedButton.icon(
                            onPressed: onClose,
                            icon: const Icon(Icons.block_rounded, size: 16),
                            label: const Text('إغلاق'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(color: AppColors.warning),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseImage(String? image) {
    if (image != null &&
        (image.startsWith('http://') || image.startsWith('https://'))) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(),
      );
    }
    if (image != null && image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_stories_outlined,
        color: AppColors.primary,
        size: 42,
      ),
    );
  }

  String _statusLabel(CourseStatus status) => switch (status) {
        CourseStatus.draft => 'مسودة',
        CourseStatus.published => 'منشورة',
        CourseStatus.closed => 'مغلقة',
        CourseStatus.completed => 'مكتملة',
      };

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

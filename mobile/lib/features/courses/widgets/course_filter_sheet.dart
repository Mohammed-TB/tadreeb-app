import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../controllers/course_controller.dart';

class CourseFilterSheet extends StatefulWidget {
  const CourseFilterSheet({
    super.key,
    this.onFilterApplied,
  });

  final ValueChanged<CourseSortOption>? onFilterApplied;

  static Future<CourseSortOption?> show(
    BuildContext context, {
    ValueChanged<CourseSortOption>? onFilterApplied,
  }) {
    return showModalBottomSheet<CourseSortOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => CourseFilterSheet(onFilterApplied: onFilterApplied),
    );
  }

  @override
  State<CourseFilterSheet> createState() => _CourseFilterSheetState();
}

class _CourseFilterSheetState extends State<CourseFilterSheet>
    with SingleTickerProviderStateMixin {
  late CourseSortOption _selectedOption;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final controller = context.read<CourseController>();
    _selectedOption = controller.sortOption;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    HapticFeedback.lightImpact();
    final controller = context.read<CourseController>();
    controller.setSortOption(_selectedOption);
    widget.onFilterApplied?.call(_selectedOption);
    Navigator.of(context).pop(_selectedOption);
  }

  void _resetFilter() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOption = CourseSortOption.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _selectedOption != CourseSortOption.none;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مقبض السحب العلوي
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // شريط العنوان وأزرار التحكم
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'فلترة وترتيب الدورات',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),

                      // زر إعادة التعيين
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: hasChanges ? 1.0 : 0.0,
                        child: TextButton.icon(
                          onPressed: hasChanges ? _resetFilter : null,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          label: Text(
                            'إعادة ضبط',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // زر الإغلاق
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                        tooltip: 'إغلاق',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16, color: AppColors.divider),

                // خيارات الفلترة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // قسم السعر
                      _buildSectionLabel(
                        title: 'الترتيب حسب السعر',
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _FilterOptionCard(
                        title: 'الأعلى سعراً',
                        subtitle: 'ترتيب الدورات من الأكثر تكلفة إلى الأقل',
                        icon: Icons.trending_up_rounded,
                        isSelected:
                            _selectedOption == CourseSortOption.priceHighToLow,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedOption =
                                _selectedOption == CourseSortOption.priceHighToLow
                                    ? CourseSortOption.none
                                    : CourseSortOption.priceHighToLow;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _FilterOptionCard(
                        title: 'الأقل سعراً',
                        subtitle: 'ترتيب الدورات من الأقل تكلفة إلى الأكثر',
                        icon: Icons.trending_down_rounded,
                        isSelected:
                            _selectedOption == CourseSortOption.priceLowToHigh,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedOption =
                                _selectedOption == CourseSortOption.priceLowToHigh
                                    ? CourseSortOption.none
                                    : CourseSortOption.priceLowToHigh;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // قسم التاريخ
                      _buildSectionLabel(
                        title: 'الترتيب حسب التاريخ',
                        icon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _FilterOptionCard(
                        title: 'الأحدث إضافة',
                        subtitle: 'عرض الدورات الجديدة والمضافة مؤخراً أولاً',
                        icon: Icons.auto_awesome_rounded,
                        isSelected:
                            _selectedOption == CourseSortOption.dateNewest,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedOption =
                                _selectedOption == CourseSortOption.dateNewest
                                    ? CourseSortOption.none
                                    : CourseSortOption.dateNewest;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _FilterOptionCard(
                        title: 'الأقرب بدءاً',
                        subtitle: 'الدورات التي يبدأ موعد انعقادها في أقرب وقت',
                        icon: Icons.event_available_rounded,
                        isSelected:
                            _selectedOption == CourseSortOption.dateStartingSoon,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedOption =
                                _selectedOption == CourseSortOption.dateStartingSoon
                                    ? CourseSortOption.none
                                    : CourseSortOption.dateStartingSoon;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // زر التطبيق
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Button(
                    text: hasChanges
                        ? 'تطبيق (${_selectedOption.label})'
                        : 'عرض بدون ترتيب (الافتراضي)',
                    icon: Icons.check_rounded,
                    height: 48,
                    borderRadius: 14,
                    fontSize: 15,
                    onTap: _applyFilter,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FilterOptionCard extends StatelessWidget {
  const _FilterOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.35)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            child: Row(
              children: [
                // أيقونة الخيار
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.field,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),

                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // مؤشر الاختيار (Radio / Checkmark)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

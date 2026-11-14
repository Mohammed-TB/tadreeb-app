
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class ListCategory extends StatefulWidget {
  const ListCategory({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.selectedCategory,
    this.initialSelectedIndex = 0,
  });

  final List<String> categories;

  // إرسال التصنيف المختار إلى الصفحة الأم
  final ValueChanged<String>? onCategorySelected;
  final String? selectedCategory;

  // التصنيف المحدد افتراضيًا
  final int initialSelectedIndex;

  @override
  State<ListCategory> createState() => _ListCategoryState();
}

class _ListCategoryState extends State<ListCategory> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.categories.isEmpty
        ? -1
        : _indexForSelectedCategory() ??
            widget.initialSelectedIndex.clamp(0, widget.categories.length - 1);
  }

  @override
  void didUpdateWidget(covariant ListCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories ||
        oldWidget.selectedCategory != widget.selectedCategory) {
      selectedIndex = widget.categories.isEmpty
          ? -1
          : _indexForSelectedCategory() ??
              widget.initialSelectedIndex.clamp(
                0,
                widget.categories.length - 1,
              );
    }
  }

  int? _indexForSelectedCategory() {
    if (widget.selectedCategory == null) return null;
    final index = widget.categories.indexOf(widget.selectedCategory!);
    return index < 0 ? null : index;
  }

  void _selectCategory(int index) {
    if (selectedIndex == index) return;

    setState(() {
      selectedIndex = index;
    });

    widget.onCategorySelected?.call(widget.categories[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        padding: EdgeInsets.zero,

        separatorBuilder: (context, index) {
          return const SizedBox(width: AppSpacing.xs);
        },

        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = selectedIndex == index;

          return _buildCategoryItem(
            category: category,
            isSelected: isSelected,
            onTap: () => _selectCategory(index),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.field,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Text(
            category,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

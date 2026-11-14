
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'text_filed.dart';

class Search extends StatelessWidget {
  const Search({
    super.key,
    this.hinText,
    this.isShowFilter = true,
    this.onFilterTap,
    this.isBorder = true,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.hasActiveFilter = false,
    this.onClear,
  });

  final String? hinText;
  final bool isShowFilter;
  final VoidCallback? onFilterTap;
  final bool isBorder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool hasActiveFilter;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // حقل البحث
          Expanded(
            child: TextFieldApp(
              hinText: hinText ?? 'ابحث هنا...',
              icon: Icons.search,
              height: 46,
              isBorder: isBorder,
              fillColor: AppColors.surface,
              borderRadius: 12,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              controller: controller,
              textInputAction: TextInputAction.search,
              suffixIcon: controller != null && controller!.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        controller!.clear();
                        onChanged?.call('');
                        onClear?.call();
                      },
                      splashRadius: 16,
                      tooltip: 'مسح',
                    )
                  : null,
            ),
          ),

          if (isShowFilter) ...[
            const SizedBox(width: AppSpacing.xs),

            // زر الفلتر
            SizedBox(
              width: 46,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: hasActiveFilter
                          ? AppColors.primaryLight.withValues(alpha: 0.5)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActiveFilter
                            ? AppColors.primary
                            : AppColors.border,
                        width: hasActiveFilter ? 1.5 : 1.0,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: hasActiveFilter
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        if (hasActiveFilter)
                          Positioned(
                            top: 7,
                            left: 7,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

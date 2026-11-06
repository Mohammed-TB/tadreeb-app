
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/textFiled.dart';

class Search extends StatelessWidget {
  const Search({
    super.key,
    this.hinText,
    this.isShowFilter = true,
    this.onFilterTap,
    this.isBorder = true,
  });

  final String? hinText;
  final bool isShowFilter;
  final VoidCallback? onFilterTap;
  final bool isBorder;

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
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.filter_list,
                        size: 25,
                        color: AppColors.accent,
                      ),
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

import 'package:flutter/material.dart';
import 'package:project_1/app/theme/app_typography.dart';

import '../../../app/theme/app_colors.dart';

class FastSummaryCard extends StatelessWidget {
  const FastSummaryCard({super.key, required this.title, required this.value});
  final String title;
  final int value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)

        ),
        child: Column(
          children: [
            Text(title,style: AppTypography.bodyLarge,),
            Text(value.toString(),style: TextStyle(
              color: AppColors.primaryDark
            ),),
          ],
        ),
      ),
    );
  }
}

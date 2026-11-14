import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import 'fast_summary_card.dart';

class ContainerFastSummaryCard extends StatelessWidget {
  const ContainerFastSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal,vertical: AppSpacing.screenVertical),
      child: Column(
        children: [
          Row(
            children: [
              FastSummaryCard(
                title: 'إجمالي الدورات',
                value: 12,
              ),
              SizedBox(width: 10,),
              FastSummaryCard(
                title:'إجمالي الطلاب' ,
                value: 100,
              ),
            ],
          ),
          SizedBox(height: 8,),
          Row(
            children: [
              FastSummaryCard(
                title: 'الدورات النشطة',
                value: 5,
              ),
              SizedBox(width: 10,),
              FastSummaryCard(
                title: 'الدورات المكتملة',
                value: 40,
              ),
            ],
          ),

        ],
      ),
    );
  }
}

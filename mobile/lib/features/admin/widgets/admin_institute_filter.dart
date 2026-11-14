import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../models/admin_institute_model.dart';

class AdminInstituteFilter extends StatelessWidget {
  const AdminInstituteFilter({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  final AdminInstituteStatus? selectedStatus;
  final ValueChanged<AdminInstituteStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <(String, AdminInstituteStatus?)>[
      ('الكل', null),
      ('نشط', AdminInstituteStatus.active),
      ('معلق', AdminInstituteStatus.pending),
      ('موقوف', AdminInstituteStatus.suspended),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = selectedStatus == option.$2;
          return ChoiceChip(
            label: Text(option.$1),
            selected: selected,
            onSelected: (_) => onChanged(option.$2),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

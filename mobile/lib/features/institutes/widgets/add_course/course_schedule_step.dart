import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import 'course_form_components.dart';

/// الخطوة الثانية: مواعيد وتفاصيل الحضور (الفترة، المقاعد، والموقع)
class CourseScheduleStep extends StatelessWidget {
  const CourseScheduleStep({
    super.key,
    required this.formKey,
    required this.startDate,
    required this.endDate,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.capacityController,
    required this.locationController,
  });

  final GlobalKey<FormState> formKey;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final TextEditingController capacityController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const CourseFormStepIntro(
            title: 'رتّب تفاصيل الحضور',
            description: 'حدد فترة الدورة، عدد المقاعد ومكان انعقادها.',
            icon: Icons.event_available_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseFormSectionCard(
            title: 'مدة الدورة',
            icon: Icons.calendar_month_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CourseFormDateField(
                      label: 'تاريخ البداية',
                      date: startDate,
                      onTap: onSelectStartDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CourseFormDateField(
                      label: 'تاريخ النهاية',
                      date: endDate,
                      onTap: onSelectEndDate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CourseFormTextField(
            controller: capacityController,
            label: 'عدد المقاعد',
            hint: 'مثال: 20',
            icon: Icons.groups_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              final capacity = int.tryParse(value?.trim() ?? '');
              if (capacity == null || capacity < 1) {
                return 'أدخل عددًا صحيحًا أكبر من صفر';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          CourseFormTextField(
            controller: locationController,
            label: 'موقع الدورة',
            hint: 'مثال: مقر المعهد - القاعة 2',
            icon: Icons.location_on_outlined,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل موقع الدورة'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const CourseFormInfoBanner(
            icon: Icons.tips_and_updates_outlined,
            message: 'يمكنك تعديل هذه التفاصيل لاحقًا من إدارة الدورات.',
          ),
        ],
      ),
    );
  }
}

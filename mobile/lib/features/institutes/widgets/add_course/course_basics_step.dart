import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/mock_data/categories_data.dart';
import 'course_form_components.dart';
import 'course_image_picker.dart';
import 'course_list_input.dart';

/// الخطوة الأولى: معلومات الدورة الأساسية (الصورة، العنوان، التصنيف، الوصف)
class CourseBasicsStep extends StatelessWidget {
  const CourseBasicsStep({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.category,
    required this.onCategoryChanged,
    required this.imageBytes,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onWhatWillLearnChanged,
    required this.onFeaturesChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? category;
  final ValueChanged<String?> onCategoryChanged;
  final Uint8List? imageBytes;
  final bool isPickingImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final ValueChanged<List<String>> onWhatWillLearnChanged;
  final ValueChanged<List<String>> onFeaturesChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const CourseFormStepIntro(
            title: 'عرّف الطلاب بدورتك',
            description: 'أضف عنوانًا واضحًا ووصفًا يساعد الطلاب على الاختيار.',
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseImagePickerCard(
            imageBytes: imageBytes,
            isPickingImage: isPickingImage,
            onPickImage: onPickImage,
            onRemoveImage: onRemoveImage,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseFormTextField(
            controller: titleController,
            label: 'اسم الدورة',
            hint: 'مثال: أساسيات البرمجة',
            icon: Icons.title,
            maxLength: 150,
            validator: (value) {
              if (value == null || value.trim().length < 3) {
                return 'أدخل اسمًا لا يقل عن 3 أحرف';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: InputDecoration(
              labelText: 'التصنيف',
              hintText: 'اختر تصنيف الدورة',
              prefixIcon: const Icon(
                Icons.category_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: categories
                .where((item) => item != 'الكل')
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onCategoryChanged,
            validator: (value) => value == null ? 'اختر تصنيف الدورة' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseFormTextField(
            controller: descriptionController,
            label: 'وصف الدورة',
            hint: 'اكتب نبذة عن محتوى الدورة',
            icon: Icons.notes_outlined,
            maxLines: 3,
            maxLength: 3000,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل وصف الدورة'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseListInput(
            label: 'ماذا سيتعلم الطالب؟',
            hint: 'مثال: إتقان أساسيات البرمجة',
            icon: Icons.school_outlined,
            onChanged: onWhatWillLearnChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseListInput(
            label: 'مميزات الدورة',
            hint: 'مثال: تطبيقات ومشاريع عملية',
            icon: Icons.stars_outlined,
            onChanged: onFeaturesChanged,
          ),
        ],
      ),
    );
  }
}

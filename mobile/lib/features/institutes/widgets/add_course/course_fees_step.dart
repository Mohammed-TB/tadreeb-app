import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import 'course_form_components.dart';

/// الخطوة الثالثة: الرسوم والدفع (سعر الدورة، مبلغ العربون، وملاحظات المراجعة)
class CourseFeesStep extends StatelessWidget {
  const CourseFeesStep({
    super.key,
    required this.formKey,
    required this.priceController,
    required this.depositController,
    required this.validateAmount,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController priceController;
  final TextEditingController depositController;
  final String? Function(String?) validateAmount;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const CourseFormStepIntro(
            title: 'راجع الرسوم قبل الإنشاء',
            description: 'حدد سعر الدورة والعربون المطلوب لحجز المقعد.',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          CourseFormSectionCard(
            title: 'تكلفة التسجيل',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              CourseFormTextField(
                controller: priceController,
                label: 'السعر الكامل',
                hint: '0',
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: validateAmount,
              ),
              const SizedBox(height: AppSpacing.md),
              CourseFormTextField(
                controller: depositController,
                label: 'مبلغ العربون',
                hint: '0',
                icon: Icons.receipt_long_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: validateAmount,
              ),
              const SizedBox(height: AppSpacing.sm),
              const CourseFormInfoBanner(
                icon: Icons.info_outline,
                message: 'يجب ألا يتجاوز العربون السعر الكامل للدورة.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const CourseFormReviewBanner(),
        ],
      ),
    );
  }
}

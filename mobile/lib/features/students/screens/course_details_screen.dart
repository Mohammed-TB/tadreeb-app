
import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import '../../../core/mock_data/institutes_data.dart';
import '../../courses/models/course_model.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  final CourseModel course;

  @override
  State<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabController;

  CourseModel get course => widget.course;

  String get instituteName {
  for (final institute in institutes) {
    if (institute.id == course.instituteID) {
      return institute.name;
    }
  }

  return 'معهد غير معروف';
}

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFull = course.isFull == true;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: Text(
          'تفاصيل الدورة',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة الدورة
            _buildCourseImage(),

            Padding(
              padding: const EdgeInsets.all(
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان والمعهد
                  _buildCourseHeader(),

                  const SizedBox(
                    height: AppSpacing.lg,
                  ),

                  // إحصائيات الدورة
                  _buildCourseStats(),

                  const SizedBox(
                    height: AppSpacing.xl,
                  ),

                  // وصف الدورة
                  _buildDescription(),

                  const SizedBox(
                    height: AppSpacing.xl,
                  ),

                  // التبويبات
                  _buildTabs(),

                  const SizedBox(
                    height: AppSpacing.lg,
                  ),

                  // محتوى التبويب الحالي
                  _buildSelectedTabContent(),

                  const SizedBox(
                    height: AppSpacing.xl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // زر التسجيل الثابت
      bottomNavigationBar: _buildEnrollButton(isFull),
    );
  }

  // ------------------------------------------
  // صورة الدورة
  // ------------------------------------------

  Widget _buildCourseImage() {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Image.asset(
        course.courseImageUrl ??
            'assets/images/english2_course.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primaryLight,
            alignment: Alignment.center,
            child: const Icon(
              Icons.school_outlined,
              size: 60,
              color: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------
  // عنوان الدورة والمعهد
  // ------------------------------------------

  Widget _buildCourseHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.category,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: AppSpacing.xs,
        ),

        Text(
          course.name,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: AppSpacing.xs,
        ),

        Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),

            const SizedBox(
              width: AppSpacing.xs,
            ),

            Expanded(
              child: Text(
                instituteName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------
  // إحصائيات الدورة
  // ------------------------------------------

  Widget _buildCourseStats() {
    return Row(
      children: [
        Expanded(
          child: _statItem(
            Icons.payments_outlined,
            'السعر',
            '${course.price.toStringAsFixed(0)} ريال',
          ),
        ),

        Expanded(
          child: _statItem(
            Icons.people_outline,
            'المقاعد',
            '${course.enrolled}/${course.capacity}',
          ),
        ),

        Expanded(
          child: _statItem(
            Icons.category_outlined,
            'التصنيف',
            course.category,
          ),
        ),
      ],
    );
  }

  Widget _statItem(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),

          const SizedBox(
            height: AppSpacing.xs,
          ),

          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(
            height: AppSpacing.xxs,
          ),

          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // وصف الدورة
  // ------------------------------------------

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'عن الدورة',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: AppSpacing.sm,
        ),

        Text(
          course.description,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------
  // التبويبات
  // ------------------------------------------

  Widget _buildTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل ومحتوى الدورة',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(
                text: 'ماذا ستتعلم؟',
              ),
              Tab(
                text: 'مميزات الدورة',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------
  // محتوى التبويب المختار
  // ------------------------------------------

  Widget _buildSelectedTabContent() {
    final isLearningTab = _tabController.index == 0;

    final items = isLearningTab
        ? course.whatWillLearn
        : course.features;

    final icon = isLearningTab
        ? Icons.check_circle_outline
        : Icons.star_outline;

    return _buildItemsList(
      items,
      icon,
    );
  }

  // ------------------------------------------
  // قائمة العناصر
  // ------------------------------------------

  Widget _buildItemsList(
      List<String> items,
      IconData icon,
      ) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'لا توجد معلومات حاليًا',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),

              const SizedBox(
                width: AppSpacing.sm,
              ),

              Expanded(
                child: Text(
                  item,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------
  // زر التسجيل
  // ------------------------------------------

  Widget _buildEnrollButton(bool isFull) {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isFull
                ? null
                : () {
              // سنربط عملية التسجيل لاحقًا
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isFull
                  ? 'الدورة مكتملة'
                  : 'التسجيل في الدورة',
              style: AppTypography.titleMedium.copyWith(
                color: isFull
                    ? AppColors.textSecondary
                    : AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

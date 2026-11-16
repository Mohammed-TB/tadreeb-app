import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/app/theme/app_typography.dart';
import 'package:project_1/core/network/api_exception.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/services/course_service.dart';
import 'package:project_1/features/courses/widgets/course_details_description.dart';
import 'package:project_1/features/courses/widgets/course_details_header.dart';
import 'package:project_1/features/courses/widgets/course_details_image.dart';
import 'package:project_1/features/courses/widgets/course_details_lists.dart';
import 'package:project_1/features/courses/widgets/course_details_stats.dart';
import 'package:project_1/features/courses/widgets/course_enroll_button.dart';
import 'package:project_1/features/institutes/controllers/institute_controller.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key, required this.course});

  final CourseModel course;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late CourseModel _course;
  bool _isCheckingAvailability = false;
  bool _hasFreshCourse = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  String _instituteName(BuildContext context, CourseModel course) {
    final institutes = context.watch<InstituteController>().institutes;
    for (final institute in institutes) {
      if (institute.id == course.instituteId) {
        return institute.name;
      }
    }

    return 'معهد غير معروف';
  }

  Future<void> _refreshAndRegister() async {
    if (_isCheckingAvailability) return;

    final courseId = _course.id;
    if (courseId == null || courseId.isEmpty) {
      _showMessage('تعذر التحقق من توفر الدورة');
      return;
    }

    setState(() => _isCheckingAvailability = true);
    try {
      final latestCourse = await context.read<CourseService>().getCourseById(
        courseId,
      );
      if (!mounted) return;

      setState(() {
        _course = latestCourse;
        _hasFreshCourse = true;
      });

      if (latestCourse.isFull) {
        _showMessage('لا توجد مقاعد متاحة حاليًا في هذه الدورة');
        return;
      }

      context.push('/course-registration', extra: latestCourse);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.statusCode == 404
            ? 'لم تعد هذه الدورة متاحة للتسجيل'
            : error.message,
      );
    } on Exception catch (error) {
      if (mounted) _showMessage('تعذر التحقق من توفر الدورة: $error');
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تفاصيل الدورة',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
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
            CourseDetailsImage(course: course),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CourseDetailsHeader(
                    course: course,
                    instituteName: _instituteName(context, course),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CourseDetailsStats(course: course),
                  const SizedBox(height: AppSpacing.lg),
                  _CourseDates(course: course),
                  const SizedBox(height: AppSpacing.xl),
                  CourseDetailsDescription(description: course.description),
                  if (course.whatWillLearn.isNotEmpty ||
                      course.features.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    CourseDetailsLists(
                      whatWillLearn: course.whatWillLearn,
                      features: course.features,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CourseEnrollButton(
        isFull: _hasFreshCourse && course.isFull,
        isLoading: _isCheckingAvailability,
        onPressed: _refreshAndRegister,
      ),
    );
  }
}

class _CourseDates extends StatelessWidget {
  const _CourseDates({required this.course});

  final CourseModel course;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'مدة الدورة',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CourseDateItem(
                  label: 'تاريخ البداية',
                  value: _formatDate(course.startDate),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CourseDateItem(
                  label: 'تاريخ النهاية',
                  value: _formatDate(course.endDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseDateItem extends StatelessWidget {
  const _CourseDateItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/features/courses/models/course_model.dart';

class CourseDetailsImage extends StatelessWidget {
  const CourseDetailsImage({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Image.asset(
        course.image ?? 'assets/images/english2_course.png',
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
}

import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import 'course_card.dart';

class ListCourses extends StatelessWidget {
  const ListCourses({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(
        height: AppSpacing.cardGap,
      ),
      itemBuilder: (context, index) {
        return CourseCard(
          number: index,
        );
      },
    );
  }
}
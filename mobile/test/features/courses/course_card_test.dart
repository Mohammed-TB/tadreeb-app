import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/mock_data/institutes_data.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/widgets/course_card.dart';

void main() {
  testWidgets('shows the populated institute name instead of the category', (
    tester,
  ) async {
    final course = CourseModel.fromJson({
      '_id': 'course-1',
      'title': 'أساسيات البرمجة',
      'category': 'تقنية',
      'instituteId': {'_id': 'institute-1', 'name': 'معهد النخبة'},
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseCard(
            course: course,
            institutes: institutes,
            showDetailsCourse: () {},
            showDetailsButton: false,
          ),
        ),
      ),
    );

    expect(find.text('معهد النخبة'), findsOneWidget);
    expect(find.text('تقنية'), findsNothing);
  });
}

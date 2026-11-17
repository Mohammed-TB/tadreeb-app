import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/institutes/widgets/courses/institute_course_card.dart';

void main() {
  testWidgets('offers and invokes reopen for a closed course', (tester) async {
    var reopened = false;
    final course = CourseModel(
      id: 'course-1',
      title: 'دورة اختبار',
      description: '',
      category: 'تقنية',
      price: 500,
      depositAmount: 100,
      capacity: 20,
      startDate: DateTime(2027, 1, 1),
      endDate: DateTime(2027, 1, 10),
      location: 'الرياض',
      status: CourseStatus.closed,
      instituteId: 'institute-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InstituteCourseCard(
              course: course,
              onReopen: () => reopened = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('إعادة فتح الدورة'), findsOneWidget);
    await tester.tap(find.text('إعادة فتح الدورة'));
    expect(reopened, isTrue);
  });
}

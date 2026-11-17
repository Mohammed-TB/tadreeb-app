import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/institutes/widgets/add_course/course_form_navigation.dart';

void main() {
  testWidgets('shows the edit save label and invokes its action', (
    tester,
  ) async {
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CourseFormStepActions(
            isLastStep: true,
            lastStepLabel: 'حفظ التعديل',
            onPrevious: () {},
            onNext: () => submitted = true,
          ),
        ),
      ),
    );

    expect(find.text('حفظ التعديل'), findsOneWidget);
    await tester.tap(find.text('حفظ التعديل'));

    expect(submitted, isTrue);
  });
}

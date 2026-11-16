import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/courses/widgets/course_enroll_button.dart';

void main() {
  testWidgets('disables registration when the student is already registered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CourseEnrollButton(
            isFull: false,
            isRegistered: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.text('تم التسجيل في الدورة'), findsOneWidget);
  });

  testWidgets('keeps registration enabled when the student is not registered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CourseEnrollButton(
            isFull: false,
            onPressed: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
    expect(find.text('التسجيل في الدورة'), findsOneWidget);
  });
}

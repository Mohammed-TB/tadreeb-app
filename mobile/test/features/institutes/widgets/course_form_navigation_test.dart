import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/institutes/screens/add_institute_course_screen.dart';
import 'package:project_1/features/institutes/widgets/add_course/course_image_picker.dart';
import 'package:project_1/features/institutes/widgets/add_course/course_form_navigation.dart';

void main() {
  testWidgets('keeps progress compact and supports selecting a step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedStep = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CourseFormStepProgress(
              steps: const ['المعلومات', 'المواعيد', 'الرسوم'],
              currentStep: 0,
              onStepSelected: (index) => selectedStep = index,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CourseFormStepProgress)).height,
      lessThanOrEqualTo(68),
    );
    expect(find.text('المعلومات'), findsOneWidget);
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('course-form-step-2')));
    expect(selectedStep, 2);
  });

  testWidgets('keeps the add-course screen usable on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AddInstituteCourseScreen()),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CourseFormStepProgress)).height,
      lessThanOrEqualTo(68),
    );
    final imagePickerTapTarget = find
        .descendant(
          of: find.byType(CourseImagePickerCard),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.getSize(imagePickerTapTarget).height, 128);
  });
}

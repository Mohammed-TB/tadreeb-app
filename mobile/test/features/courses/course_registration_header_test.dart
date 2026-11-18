import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/app/theme/app_spacing.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/widgets/course_registration_components.dart';

void main() {
  testWidgets('keeps course summary and progress compact on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final course = CourseModel(
      id: 'course-id',
      title: 'دورة طويلة في تطوير التطبيقات والبرمجة الحديثة',
      description: '',
      category: 'تقنية',
      price: 1500,
      depositAmount: 300,
      capacity: 20,
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 5),
      location: 'حضوري',
      instituteId: 'institute-id',
    );
    final headerKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                key: headerKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CourseRegistrationCourseSummary(course: course),
                    CourseRegistrationStepHeader(
                      steps: const ['البيانات', 'الدفع', 'السند'],
                      currentStep: 0,
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(headerKey)).height,
      lessThanOrEqualTo(AppSpacing.section + 60),
    );
    expect(find.text(course.title), findsOneWidget);
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);
  });
}

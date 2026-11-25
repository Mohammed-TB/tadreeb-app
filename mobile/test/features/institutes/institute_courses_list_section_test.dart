import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/institutes/widgets/courses/institute_courses_list_section.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  Widget buildSection({
    required bool hasActiveFilters,
    required VoidCallback onClearFilters,
    required VoidCallback onAddCourse,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: InstituteCoursesListSection(
          courses: const [],
          isLoading: isLoading,
          errorMessage: null,
          hasActiveFilters: hasActiveFilters,
          onRetry: () {},
          onClearFilters: onClearFilters,
          onAddCourse: onAddCourse,
          onEditCourse: (_) {},
          onPublishCourse: (_) {},
          onCloseCourse: (_) {},
          onReopenCourse: (_) {},
          onDeleteCourse: (_) {},
        ),
      ),
    );
  }

  testWidgets('shows course-card skeletons while the API request is pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(
        hasActiveFilters: false,
        onClearFilters: () {},
        onAddCourse: () {},
        isLoading: true,
      ),
    );

    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an empty-results action that clears active filters', (
    tester,
  ) async {
    var filtersCleared = false;
    await tester.pumpWidget(
      buildSection(
        hasActiveFilters: true,
        onClearFilters: () => filtersCleared = true,
        onAddCourse: () {},
      ),
    );

    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
    await tester.tap(find.text('إلغاء الفلترة'));
    expect(filtersCleared, isTrue);
  });

  testWidgets('shows an add-course action when there are no courses', (
    tester,
  ) async {
    var addRequested = false;
    await tester.pumpWidget(
      buildSection(
        hasActiveFilters: false,
        onClearFilters: () {},
        onAddCourse: () => addRequested = true,
      ),
    );

    expect(find.text('لم تقم بإضافة أي دورة بعد'), findsOneWidget);
    await tester.tap(find.text('إضافة دورة جديدة'));
    expect(addRequested, isTrue);
  });
}

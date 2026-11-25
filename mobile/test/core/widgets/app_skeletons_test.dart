import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/widgets/app_skeletons.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('renders skeleton bones for a list while data is loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppSkeletonList(itemCount: 3))),
    );

    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsOneWidget,
    );
    expect(find.byWidgetPredicate((widget) => widget is Bone), findsWidgets);
  });
}

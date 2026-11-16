import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/institutes/models/institute_model.dart';
import 'package:project_1/features/students/widgets/institute_card.dart';

void main() {
  const institute = InstituteModel(
    id: 'institute-1',
    ownerUserId: 'owner-1',
    name: 'معهد الاختبار',
    address: 'الرياض',
    phone: '0500000000',
  );

  for (final layout in InstituteCardLayout.values) {
    testWidgets('supports tapping the ${layout.name} card', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstituteCard(
              institute: institute,
              layout: layout,
              showDetailsButton: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('معهد الاختبار'));
      expect(tapped, isTrue);
    });
  }

  testWidgets('places horizontal favorite action to the left of the image', (
    tester,
  ) async {
    var favoriteTapped = false;
    var cardTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: InstituteCard(
                  institute: institute,
                  layout: InstituteCardLayout.horizontal,
                  showDetailsButton: false,
                  onTap: () => cardTapped = true,
                  onFavoriteTap: () => favoriteTapped = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final favoriteButton = find.byTooltip('إضافة إلى المفضلة');
    final instituteImage = find.byIcon(Icons.account_balance_outlined);
    expect(
      tester.getCenter(favoriteButton).dx,
      lessThan(tester.getCenter(instituteImage).dx),
    );

    await tester.tap(favoriteButton);
    await tester.pumpAndSettle();

    expect(favoriteTapped, isTrue);
    expect(cardTapped, isFalse);
  });
}

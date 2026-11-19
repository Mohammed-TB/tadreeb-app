import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/auth/services/auth_service.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/courses/screens/student/course_registration_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('copies the deposit account number from the payment step', (
    tester,
  ) async {
    final authController = AuthController(AuthService());
    addTearDown(authController.dispose);
    final course = CourseModel(
      id: 'course-id',
      title: 'دورة اختبارية',
      description: '',
      category: 'تقنية',
      price: 1000,
      depositAmount: 250,
      capacity: 10,
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 5),
      location: 'حضوري',
      instituteId: 'institute-id',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            ...PhoneFieldLocalization.delegates,
          ],
          home: CourseRegistrationScreen(course: course),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'محمد علي أحمد صالح');
    await tester.enterText(find.byType(TextField).at(1), '777123456');
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('نسخ رقم الحساب'));
    await tester.pumpAndSettle();

    final copiedValue = await Clipboard.getData(Clipboard.kTextPlain);
    expect(copiedValue?.text, '254000321');
    expect(find.text('تم نسخ رقم الحساب'), findsOneWidget);
  });
}

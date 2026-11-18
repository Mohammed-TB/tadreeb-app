import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/reservations/controllers/institute_reservation_controller.dart';
import 'package:project_1/features/reservations/services/reservation_service.dart';
import 'package:project_1/features/reservations/widgets/in_person_registration_sheet.dart';

void main() {
  late InstituteReservationController controller;
  final course = CourseModel(
    id: 'course-id',
    title: 'دورة اختبارية',
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

  setUp(() {
    controller = InstituteReservationController(
      ReservationService(
        apiClient: ApiClient(tokenStorage: TokenStorageService()),
      ),
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpSheet(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          ...PhoneFieldLocalization.delegates,
        ],
        home: Scaffold(
          body: InPersonRegistrationSheet(
            courses: [course],
            controller: controller,
          ),
        ),
      ),
    );
  }

  testWidgets('requires a four-part student name', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'محمد أحمد علي');
    await tester.tap(find.text('تأكيد التسجيل'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل الاسم الرباعي كاملًا'), findsOneWidget);
  });

  testWidgets('derives displayed amount from the selected course option', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('1500 ريال'), findsOneWidget);
    expect(find.text('المبلغ المدفوع'), findsNothing);

    final paymentDropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.tap(paymentDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('عربون · 300 ريال').last);
    await tester.pumpAndSettle();

    expect(find.text('300 ريال'), findsOneWidget);
  });
}

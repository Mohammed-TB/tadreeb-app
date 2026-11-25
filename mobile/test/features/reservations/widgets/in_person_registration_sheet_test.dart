import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/core/widgets/app_phone_field.dart';
import 'package:project_1/features/courses/models/course_model.dart';
import 'package:project_1/features/reservations/controllers/institute_reservation_controller.dart';
import 'package:project_1/features/reservations/services/reservation_service.dart';
import 'package:project_1/features/reservations/widgets/in_person_registration_sheet.dart';

class _FakeReservationService extends ReservationService {
  _FakeReservationService({this.studentName})
    : super(apiClient: ApiClient(tokenStorage: TokenStorageService()));

  final String? studentName;
  String? lookedUpPhone;

  @override
  Future<String?> findStudentNameByPhone(String phone) async {
    lookedUpPhone = phone;
    return studentName;
  }
}

void main() {
  late InstituteReservationController controller;
  late _FakeReservationService reservationService;
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
    reservationService = _FakeReservationService(
      studentName: 'محمد أحمد علي صالح',
    );
    controller = InstituteReservationController(reservationService);
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

    expect(find.text('1,500 ر.ي'), findsOneWidget);
    expect(find.text('المبلغ المدفوع'), findsNothing);

    final paymentDropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.tap(paymentDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('عربون · 300 ر.ي').last);
    await tester.pumpAndSettle();

    expect(find.text('300 ر.ي'), findsOneWidget);
  });

  testWidgets('fills a previous student name after entering their phone', (
    tester,
  ) async {
    await pumpSheet(tester);

    final phoneField = find.descendant(
      of: find.byType(AppPhoneField),
      matching: find.byType(TextField),
    );
    await tester.enterText(phoneField, '777629893');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(reservationService.lookedUpPhone, '+967777629893');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'محمد أحمد علي صالح',
    );
    expect(find.text('تم العثور على الطالب وتعبئة اسمه'), findsOneWidget);
  });

  testWidgets('does not overwrite a manually entered student name', (
    tester,
  ) async {
    await pumpSheet(tester);

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'اسم يدوي للطالب');
    final phoneField = find.descendant(
      of: find.byType(AppPhoneField),
      matching: find.byType(TextField),
    );
    await tester.enterText(phoneField, '777629893');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(nameField).controller!.text,
      'اسم يدوي للطالب',
    );
    expect(
      find.text('تم العثور على الطالب، احتفظنا بالاسم الذي أدخلته'),
      findsOneWidget,
    );
  });
}

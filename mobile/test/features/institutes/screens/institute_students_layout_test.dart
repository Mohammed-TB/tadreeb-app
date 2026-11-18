import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/core/widgets/search.dart';
import 'package:project_1/features/institutes/screens/institute_students_screen.dart';
import 'package:project_1/features/institutes/widgets/student_summary_card.dart';
import 'package:project_1/features/reservations/controllers/institute_reservation_controller.dart';
import 'package:project_1/features/reservations/models/reservation_model.dart';
import 'package:project_1/features/reservations/services/reservation_service.dart';

class _StudentsLayoutController extends InstituteReservationController {
  _StudentsLayoutController()
    : _testReservations = List.generate(
        30,
        (index) => ReservationModel(
          id: 'reservation-$index',
          studentName: 'طالب رقم $index',
          studentPhone: '+96777712345${index % 10}',
          courseId: 'course-$index',
          courseTitle: 'دورة رقم $index',
          bookingType: 'online',
          paymentOption: 'full',
          totalAmount: 500,
          amountToPay: 500,
          amountPaid: 0,
          paymentStatus: 'unpaid',
          status: 'confirmed',
          createdAt: DateTime(2026, 11, 17),
          updatedAt: DateTime(2026, 11, 17),
        ),
      ),
      super(
        ReservationService(
          apiClient: ApiClient(tokenStorage: TokenStorageService()),
        ),
      );

  final List<ReservationModel> _testReservations;

  @override
  List<ReservationModel> get reservations => _testReservations;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchReservations({bool forceRefresh = false}) async {}
}

void main() {
  testWidgets('keeps student search and filters fixed while scrolling cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _StudentsLayoutController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<InstituteReservationController>.value(
        value: controller,
        child: const MaterialApp(
          home: Scaffold(body: InstituteStudentsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final search = find.byType(Search);
    final searchTop = tester.getTopLeft(search).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(search).dy, searchTop);
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.text('الطلاب المسجلون'), findsOneWidget);
  });
}

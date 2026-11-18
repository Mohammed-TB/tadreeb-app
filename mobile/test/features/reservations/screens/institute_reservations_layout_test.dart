import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/core/widgets/search.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/auth/services/auth_service.dart';
import 'package:project_1/features/reservations/controllers/institute_reservation_controller.dart';
import 'package:project_1/features/reservations/models/reservation_model.dart';
import 'package:project_1/features/reservations/screens/institute_reservations_screen.dart';
import 'package:project_1/features/reservations/services/reservation_service.dart';

class _LayoutReservationController extends InstituteReservationController {
  _LayoutReservationController()
    : _testReservations = List.generate(
        30,
        (index) => ReservationModel(
          id: 'reservation-$index',
          studentName: 'طالب رقم $index',
          studentPhone: '+967777123456',
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
  List<ReservationModel> get filteredReservations => _testReservations;

  @override
  int get totalCount => _testReservations.length;

  @override
  int get pendingCount => 0;

  @override
  int get confirmedCount => _testReservations.length;

  @override
  int get rejectedCount => 0;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchReservations({bool forceRefresh = false}) async {}
}

void main() {
  Future<({AuthController authController, _LayoutReservationController controller})>
  pumpReservationsInsideShell(WidgetTester tester) async {
    final reservationController = _LayoutReservationController();
    final authController = AuthController(
      AuthService(apiClient: ApiClient(tokenStorage: TokenStorageService())),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<InstituteReservationController>.value(
            value: reservationController,
          ),
          ChangeNotifierProvider<AuthController>.value(value: authController),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const InstituteReservationsScreen(),
              ),
            ),
            bottomNavigationBar: const SizedBox(height: 76),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (authController: authController, controller: reservationController);
  }

  testWidgets('keeps filters fixed and opens the default-width drawer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final reservationController = _LayoutReservationController();
    final authController = AuthController(
      AuthService(apiClient: ApiClient(tokenStorage: TokenStorageService())),
    );
    addTearDown(reservationController.dispose);
    addTearDown(authController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<InstituteReservationController>.value(
              value: reservationController,
            ),
            ChangeNotifierProvider<AuthController>.value(value: authController),
          ],
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: InstituteReservationsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchBar = find.byType(Search);
    final searchTop = tester.getTopLeft(searchBar).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(searchBar).dy, searchTop);
    expect(find.text('الكل (30)'), findsOneWidget);

    await tester.tap(find.byTooltip('القائمة الرئيسية'));
    await tester.pumpAndSettle();

    final drawerWidth = tester.getSize(find.byType(Drawer)).width;
    expect(drawerWidth, lessThan(360));
    expect(drawerWidth, 304);
  });

  testWidgets('opens reservation details with a full-height default-width drawer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controllers = await pumpReservationsInsideShell(tester);
    addTearDown(controllers.controller.dispose);
    addTearDown(controllers.authController.dispose);

    await tester.tap(find.text('طالب رقم 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('القائمة الرئيسية'));
    await tester.pumpAndSettle();

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    final drawerSize = tester.getSize(find.byType(Drawer));
    expect(drawer.width, isNull);
    expect(drawerSize.width, 304);
    expect(drawerSize.height, 760);
  });
}

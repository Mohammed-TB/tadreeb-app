import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_1/core/network/api_client.dart';
import 'package:project_1/core/network/token_storage_service.dart';
import 'package:project_1/core/widgets/app_drawer.dart';
import 'package:project_1/core/widgets/app_shell.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/auth/services/auth_service.dart';
import 'package:project_1/features/institutes/widgets/courses/institute_courses_header.dart';

void main() {
  testWidgets('opens the shell drawer at full height from the courses header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authController = AuthController(
      AuthService(apiClient: ApiClient(tokenStorage: TokenStorageService())),
    );
    addTearDown(authController.dispose);
    final shellScaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: MaterialApp(
          home: Scaffold(
            key: shellScaffoldKey,
            drawer: const AppDrawer(),
            body: AppShellDrawerScope(
              openDrawer: () => shellScaffoldKey.currentState!.openDrawer(),
              child: const Scaffold(body: InstituteCoursesHeader()),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('القائمة الرئيسية'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(tester.getSize(find.byType(Drawer)).width, 304);
    expect(tester.getSize(find.byType(Drawer)).height, 760);
  });
}

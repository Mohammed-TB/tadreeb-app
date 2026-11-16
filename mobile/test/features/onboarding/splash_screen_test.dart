import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/auth/models/user_model.dart';
import 'package:project_1/features/auth/services/auth_service.dart';
import 'package:project_1/features/onboarding/screens/splash_screen.dart';
import 'package:provider/provider.dart';

class _TestAuthController extends AuthController {
  _TestAuthController() : super(AuthService());

  bool _isInitializing = true;

  @override
  bool get isInitializing => _isInitializing;

  @override
  UserModel? get currentUser => null;

  void finishInitialization() {
    _isInitializing = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('animates progress from 1 to 100 over five seconds', (
    tester,
  ) async {
    final authController = _TestAuthController();
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('login destination')),
        ),
      ],
    );
    addTearDown(authController.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('1%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('50%'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('100%'), findsOneWidget);

    authController.finishInitialization();
    await tester.pumpAndSettle();
    expect(find.text('login destination'), findsOneWidget);
  });
}

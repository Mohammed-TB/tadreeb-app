import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/auth/controllers/auth_controller.dart';
import 'package:project_1/features/auth/services/auth_service.dart';

void main() {
  test('continues as a guest without creating an authenticated user', () {
    final controller = AuthController(AuthService());
    addTearDown(controller.dispose);

    controller.continueAsGuest();

    expect(controller.isGuest, isTrue);
    expect(controller.currentUser, isNull);
    expect(controller.isInitializing, isFalse);
  });

  test('ending a guest session does not require server logout', () async {
    final controller = AuthController(AuthService());
    addTearDown(controller.dispose);
    controller.continueAsGuest();

    await controller.logout();

    expect(controller.isGuest, isFalse);
    expect(controller.currentUser, isNull);
  });
}

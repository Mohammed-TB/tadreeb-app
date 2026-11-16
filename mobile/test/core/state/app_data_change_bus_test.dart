import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/state/app_data_change_bus.dart';

void main() {
  test('broadcasts local data changes to all active listeners', () async {
    final bus = AppDataChangeBus();
    final firstListener = <AppDataChange>[];
    final secondListener = <AppDataChange>[];
    final firstSubscription = bus.changes.listen(firstListener.add);
    final secondSubscription = bus.changes.listen(secondListener.add);

    bus.notifyChanged(
      AppDataDomain.reservations,
      AppDataChangeOrigin.courseRegistration,
      audience: AppDataAudience.student,
    );

    expect(firstListener, hasLength(1));
    expect(firstListener.single.domain, AppDataDomain.reservations);
    expect(firstListener.single.origin, AppDataChangeOrigin.courseRegistration);
    expect(firstListener.single.audience, AppDataAudience.student);
    expect(secondListener, hasLength(1));

    await firstSubscription.cancel();
    await secondSubscription.cancel();
    await bus.dispose();
  });
}

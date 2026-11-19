import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/core/routing/guest_route_policy.dart';

void main() {
  test('allows guest access to public browsing routes', () {
    expect(GuestRoutePolicy.canAccess('/home_screen'), isTrue);
    expect(GuestRoutePolicy.canAccess('/courses_screen'), isTrue);
    expect(GuestRoutePolicy.canAccess('/course-details'), isTrue);
    expect(GuestRoutePolicy.canAccess('/institutes_screen'), isTrue);
    expect(GuestRoutePolicy.canAccess('/institute-details'), isTrue);
  });

  test('blocks guest access to authenticated routes', () {
    expect(GuestRoutePolicy.canAccess('/favorites'), isFalse);
    expect(GuestRoutePolicy.canAccess('/course-registration'), isFalse);
    expect(GuestRoutePolicy.canAccess('/my_reservations'), isFalse);
    expect(GuestRoutePolicy.canAccess('/institute_dashboard'), isFalse);
  });
}

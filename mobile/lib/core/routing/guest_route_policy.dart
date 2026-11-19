class GuestRoutePolicy {
  const GuestRoutePolicy._();

  static const _accessiblePaths = {
    '/onboarding',
    '/login',
    '/register',
    '/home_screen',
    '/courses_screen',
    '/course-details',
    '/institutes_screen',
    '/institute-details',
  };

  static bool canAccess(String matchedLocation) =>
      _accessiblePaths.contains(matchedLocation);
}

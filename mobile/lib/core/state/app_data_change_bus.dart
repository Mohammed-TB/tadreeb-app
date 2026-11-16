import 'dart:async';

enum AppDataDomain { courses, reservations, institutes }

enum AppDataAudience { student, instituteOwner, admin }

enum AppDataChangeOrigin {
  courseManagement,
  courseRegistration,
  studentReservations,
  instituteReservations,
  adminInstitutes,
}

class AppDataChange {
  const AppDataChange(this.domain, this.origin, this.audience);

  final AppDataDomain domain;
  final AppDataChangeOrigin origin;
  final AppDataAudience audience;
}

class AppDataChangeBus {
  final StreamController<AppDataChange> _changes =
      StreamController<AppDataChange>.broadcast(sync: true);

  Stream<AppDataChange> get changes => _changes.stream;

  void notifyChanged(
    AppDataDomain domain,
    AppDataChangeOrigin origin, {
    required AppDataAudience audience,
  }) {
    _changes.add(AppDataChange(domain, origin, audience));
  }

  Future<void> dispose() => _changes.close();
}

import 'package:project_1/features/reservations/models/reservation_model.dart';

class InstituteStudentSummary {
  const InstituteStudentSummary({
    required this.name,
    required this.phone,
    required this.email,
    required this.registrations,
  });

  final String name;
  final String phone;
  final String email;
  final List<ReservationModel> registrations;
}
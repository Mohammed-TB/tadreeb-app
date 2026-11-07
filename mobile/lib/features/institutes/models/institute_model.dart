
import '../../enrollments/models/booking_settings_model.dart';

class InstituteModel {
  final String id;
  final String ownerUserId;

  final String name;
  final String address;
  final String phone;
  final String? imageUrl;

  final BookingSettingsModel bookingSettings;

  const InstituteModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.address,
    required this.phone,
    this.imageUrl,
    this.bookingSettings = const BookingSettingsModel(),
  });
}

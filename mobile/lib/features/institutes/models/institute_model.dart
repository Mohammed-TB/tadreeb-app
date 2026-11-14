


class InstituteModel {
  final String id;
  final String ownerUserId;

  final String name;
  final String address;
  final String phone;
  final String? imageUrl;

  // final BookingSettingsModel bookingSettings;

  const InstituteModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.address,
    required this.phone,
    this.imageUrl,
    // this.bookingSettings = const BookingSettingsModel(),
  });

  factory InstituteModel.fromJson(Map<String, dynamic> json) {
    return InstituteModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      ownerUserId: (json['ownerId'] ?? json['ownerUserId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      imageUrl: (json['logo'] ?? json['imageUrl'])?.toString(),
    );
  }
}

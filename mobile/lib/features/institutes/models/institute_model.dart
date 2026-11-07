class InstituteModel {
  final String id;
  final String ownerUserId;

  final String name;
  final String address;
  final String phone;
  final String? imageUrl;

  const InstituteModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.address,
    required this.phone,
    this.imageUrl,
  });
}
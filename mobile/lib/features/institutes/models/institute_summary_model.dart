
class InstituteSummaryModel {
  final String id;
  final String name;
  final String? address;
  final String? logo;

  const InstituteSummaryModel({
    required this.id,
    required this.name,
    this.address,
    this.logo,
  });

  factory InstituteSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InstituteSummaryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: json['address']?.toString(),
      logo: json['logo']?.toString(),
    );
  }
}

class StudentProfileModel {
  const StudentProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.englishName,
  });

  final String id;
  final String userId;
  final String name;
  final String? englishName;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'])?.toString();
    final userId = json['userId']?.toString();
    final name = json['name'];
    if (id == null || userId == null || name is! String) {
      throw const FormatException('بيانات ملف الطالب غير مكتملة');
    }
    return StudentProfileModel(
      id: id,
      userId: userId,
      name: name,
      englishName: json['englishName']?.toString(),
    );
  }
}

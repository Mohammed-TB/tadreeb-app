enum UserRole { student, instituteOwner, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? status;
  final String? authProvider;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.student,
    this.status,
    this.authProvider,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'] ?? json['userId'];
    final name = json['name'];
    final email = json['email'];
    final roleName = json['role'];

    if (id is! String || name is! String || email is! String) {
      throw const FormatException('بيانات المستخدم المستلمة غير مكتملة');
    }

    final role = switch (roleName) {
      'student' => UserRole.student,
      'instituteOwner' => UserRole.instituteOwner,
      'admin' => UserRole.admin,
      _ => throw const FormatException('دور المستخدم المستلم غير صالح'),
    };

    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: json['phone'] as String?,
      role: role,
      status: json['status'] as String?,
      authProvider: json['authProvider'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'status': status,
    'authProvider': authProvider,
  };

  bool get isStudent => role == UserRole.student;

  bool get isInstituteOwner => role == UserRole.instituteOwner;

  bool get isAdmin => role == UserRole.admin;
}

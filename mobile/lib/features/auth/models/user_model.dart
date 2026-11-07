
enum UserRole {
  student,
  instituteOwner,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.student,
  });

  bool get isStudent => role == UserRole.student;

  bool get isInstituteOwner =>
      role == UserRole.instituteOwner;

  bool get isAdmin => role == UserRole.admin;
}

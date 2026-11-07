import '../../auth/models/user_model.dart';

class StudentModel extends UserModel {
  const StudentModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
  });
}
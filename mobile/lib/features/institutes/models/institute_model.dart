import 'package:project_1/features/auth/models/user_model.dart';

class InstituteModel extends UserModel {
  final String instituteID;
  final String instituteName;
  final String instituteAddress;
  final String institutePhone;
  final String? instituteImageUrl;

  InstituteModel({
    required this.instituteID,
    required this.instituteName,
    required this.instituteAddress,
    required this.institutePhone,
    required super.id,
    required super.email,
    required super.password,
    required super.name,
    this.instituteImageUrl,
  });
}

List<InstituteModel> institutes = [
  InstituteModel(
    instituteID: 'inst1',
    instituteName: 'معهد الراقي',
    instituteAddress: 'حضرموت_الشحر',
    institutePhone: '555-1234',
    instituteImageUrl: 'assets/images/institute_alraqi.png',
    id: 'user1',
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
  ),

];

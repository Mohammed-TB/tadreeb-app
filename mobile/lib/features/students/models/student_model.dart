import 'package:project_1/features/auth/models/user_model.dart';
import 'package:project_1/features/courses/models/course_model.dart';

class StudentModel extends UserModel {
  final List<CourseModel> course;
  StudentModel({
    required super.id,
    required super.name,
    required super.email,
    required super.password,
    required this.course,
  });
}

List<StudentModel> students = [
  StudentModel(
    id: 'user3',
    name: 'Bob Johnson',
    email: 'bob@example.com',
    password: 'password789',
    course: [],
  ),
];

List <String> categories = [
  'الكل',
  'محاسبة',
  'إدارة',
  'برمجة',
  'تصميم',
  'خياطة',
  'أخرى'

];

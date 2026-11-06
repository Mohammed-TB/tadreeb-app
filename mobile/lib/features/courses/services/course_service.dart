import '../models/course_model.dart';

class CourseService {
  final List<CourseModel> _courses = courses;

  Future<List<CourseModel>> getCourses() async {
    await Future.delayed(const Duration(seconds: 1));

    return _courses;
  }
}
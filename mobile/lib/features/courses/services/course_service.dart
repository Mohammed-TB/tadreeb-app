import '../models/course_model.dart';
import '../../../core/mock_data/courses_data.dart';

class CourseService {
  final List<CourseModel> _courses = List.of(courses);

  Future<List<CourseModel>> getCourses() async {
    await Future.delayed(const Duration(seconds: 1));

    return _courses;
  }
}
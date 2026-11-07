import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseController extends ChangeNotifier {
  final CourseService _courseService;

  CourseController(this._courseService);

  List<CourseModel> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CourseModel> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await _courseService.getCourses();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    CourseModel? getCourseById(String courseId) {
    try {
      return _courses.firstWhere(
        (course) => course.id == courseId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await _courseService.getCourses();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh booking counts for a course.
Future<void> updateBookingCounts({
  required String courseId,
  required int confirmedBookings,
  required int reservedSeats,
}) async {
  await _courseService.updateBookingCounts(
    courseId: courseId,
    confirmedBookings: confirmedBookings,
    reservedSeats: reservedSeats,
  );

  final updatedCourse = _courseService.getCourseById(courseId);

  if (updatedCourse == null) return;

  _courses = _courses.map((course) {
    return course.id == courseId ? updatedCourse : course;
  }).toList();

  notifyListeners();
}
}
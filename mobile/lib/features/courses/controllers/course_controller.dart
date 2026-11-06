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
}
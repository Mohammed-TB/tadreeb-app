
import '../models/course_model.dart';
import '../../../core/mock_data/courses_data.dart';

class CourseService {
  final List<CourseModel> _courses = List.of(courses);

  // Keep the original enrolled count as a baseline.
  late final Map<String, int> _initialEnrolledCounts = {
    for (final course in _courses) course.id: course.enrolled,
  };

  Future<List<CourseModel>> getCourses() async {
    await Future.delayed(const Duration(seconds: 1));

    return List.unmodifiable(_courses);
  }

  // Get a course by ID.
  CourseModel? getCourseById(String courseId) {
    try {
      return _courses.firstWhere(
        (course) => course.id == courseId,
      );
    } catch (_) {
      return null;
    }
  }

  // Update booking counts using the original enrolled count.
  Future<void> updateBookingCounts({
    required String courseId,
    required int confirmedBookings,
    required int reservedSeats,
  }) async {
    final index = _courses.indexWhere(
      (course) => course.id == courseId,
    );

    if (index == -1) {
      throw Exception('الدورة غير موجودة');
    }

    final course = _courses[index];
    final initialEnrolled = _initialEnrolledCounts[courseId]!;

    final totalEnrolled = initialEnrolled + confirmedBookings;

    if (confirmedBookings < 0 ||
        reservedSeats < 0 ||
        totalEnrolled + reservedSeats > course.capacity) {
      throw Exception('عدد المقاعد غير صالح');
    }

    _courses[index] = course.copyWith(
      enrolled: totalEnrolled,
      reservedSeats: reservedSeats,
    );
  }

  // Update the number of enrolled students.
  Future<void> updateEnrolledCount({
    required String courseId,
    required int enrolled,
  }) async {
    final index = _courses.indexWhere(
      (course) => course.id == courseId,
    );

    if (index == -1) {
      throw Exception('الدورة غير موجودة');
    }

    final course = _courses[index];

    if (enrolled < 0 || enrolled > course.capacity) {
      throw Exception('عدد المقاعد غير صالح');
    }

    _courses[index] = course.copyWith(
      enrolled: enrolled,
    );
  }
}

import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../models/course_model.dart';
import '../models/course_pagination_model.dart';

class CourseService {
  CourseService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CoursesResponse> getCourses({
    String? search,
    String? category,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '/api/courses',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
        'limit': limit,
      },
    );

    final coursesJson = response['data'] as List;

    return CoursesResponse(
      courses: coursesJson
          .map((course) => CourseModel.fromJson(course))
          .toList(),
      pagination: CoursePaginationModel.fromJson(response['pagination']),
    );
  }

  Future<List<CourseModel>> getMyCourses() async {
    final response = await _apiClient.get(
      '/api/institutes/me/courses',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('بيانات دورات المعهد غير صالحة');
    }

    return data.map((course) {
      if (course is! Map<String, dynamic>) {
        throw const FormatException('بيانات إحدى الدورات غير صالحة');
      }
      return CourseModel.fromJson(course);
    }).toList();
  }

  Future<CourseModel> createCourse({
    required String title,
    required String description,
    required String category,
    required double price,
    required double depositAmount,
    required int capacity,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    List<String> whatWillLearn = const [],
    List<String> features = const [],
    List<int>? imageBytes,
    String? imageName,
    String? imageContentType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/institutes/me/courses',
      authenticated: true,
      fields: {
        'title': title,
        'description': description,
        'category': category,
        'price': price.toString(),
        'depositAmount': depositAmount.toString(),
        'capacity': capacity.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'location': location,
        'whatWillLearn': jsonEncode(whatWillLearn),
        'features': jsonEncode(features),
      },
      fileBytes: imageBytes,
      fileField: imageBytes == null ? null : 'image',
      fileName: imageName,
      contentType: imageContentType,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات الدورة المنشأة');
    }
    return CourseModel.fromJson(data);
  }

  Future<CourseModel> publishCourse(String courseId) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/courses/$courseId/publish',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات الدورة بعد النشر');
    }
    return CourseModel.fromJson(data);
  }

  Future<CourseModel> closeCourse(String courseId) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/courses/$courseId/close',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات الدورة بعد الإغلاق');
    }
    return CourseModel.fromJson(data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _apiClient.delete(
      '/api/institutes/me/courses/$courseId',
      authenticated: true,
    );
  }
}

class CoursesResponse {
  final List<CourseModel> courses;
  final CoursePaginationModel pagination;

  const CoursesResponse({required this.courses, required this.pagination});
}

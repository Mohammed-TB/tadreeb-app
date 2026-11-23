import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/cache/public_data_cache.dart';
import '../../../core/utils/saudi_date.dart';
import '../models/course_model.dart';
import '../models/course_pagination_model.dart';

class CourseService {
  CourseService({required ApiClient apiClient, PublicApiCache? publicCache})
    : _apiClient = apiClient,
      _publicCache = publicCache;

  final ApiClient _apiClient;
  final PublicApiCache? _publicCache;

  static const _courseListTtl = Duration(minutes: 5);
  static const _courseCategoriesTtl = Duration(hours: 1);
  static const _courseDetailsTtl = Duration(minutes: 10);

  Future<List<String>> getCourseCategories({bool forceRefresh = false}) async {
    const path = '/api/courses/categories';
    final cache = _publicCache;
    if (cache == null) {
      final response = await _apiClient.getPublic(path);
      final data = response.data;
      if (data == null) {
        throw const FormatException('قائمة تصنيفات الدورات غير صالحة');
      }
      return _parseCategories(data);
    }

    final key = cache.keyFor(path, const {});
    final result = await cache.fetchJson(
      key: key,
      ttl: _courseCategoriesTtl,
      forceRefresh: forceRefresh,
      fetch: (etag) async {
        final response = await _apiClient.getPublic(path, ifNoneMatch: etag);
        return PublicCacheFetch(
          data: response.data,
          etag: response.etag,
          notModified: response.notModified,
        );
      },
    );
    return _parseCategories(result.data);
  }

  List<String> _parseCategories(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List || data.any((category) => category is! String)) {
      throw const FormatException('قائمة تصنيفات الدورات غير صالحة');
    }
    return data
        .cast<String>()
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<CoursesResponse> getCourses({
    String? search,
    String? category,
    String? instituteId,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final result = await loadCourses(
      search: search,
      category: category,
      instituteId: instituteId,
      page: page,
      limit: limit,
      forceRefresh: forceRefresh,
    );
    return result.data;
  }

  Future<CoursesResponse?> getCachedCourses({
    String? search,
    String? category,
    String? instituteId,
    int page = 1,
    int limit = 10,
  }) async {
    final cache = _publicCache;
    if (cache == null) return null;

    final queryParameters = _courseQuery(
      search: search,
      category: category,
      instituteId: instituteId,
      page: page,
      limit: limit,
    );
    final key = cache.keyFor('/api/courses', queryParameters);
    final entry = await cache.read(key);
    return entry == null ? null : _parseCourses(entry.data);
  }

  Future<PublicDataResult<CoursesResponse>> loadCourses({
    String? search,
    String? category,
    String? instituteId,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cache = _publicCache;
    final queryParameters = _courseQuery(
      search: search,
      category: category,
      instituteId: instituteId,
      page: page,
      limit: limit,
    );
    if (cache == null) {
      final response = await _apiClient.get(
        '/api/courses',
        queryParameters: queryParameters,
      );
      return PublicDataResult(data: _parseCourses(response), changed: true);
    }

    final key = cache.keyFor('/api/courses', queryParameters);
    final cachedResult = await cache.fetchJson(
      key: key,
      ttl: _courseListTtl,
      forceRefresh: forceRefresh,
      fetch: (etag) async {
        final response = await _apiClient.getPublic(
          '/api/courses',
          queryParameters: queryParameters,
          ifNoneMatch: etag,
        );
        if (!response.notModified) {
          final data = response.data;
          if (data == null) {
            throw const FormatException('بيانات الدورات الواردة غير صالحة');
          }
          _parseCourses(data);
        }
        return PublicCacheFetch(
          data: response.data,
          etag: response.etag,
          notModified: response.notModified,
        );
      },
    );
    return PublicDataResult(
      data: _parseCourses(cachedResult.data),
      changed: cachedResult.changed,
    );
  }

  Map<String, dynamic> _courseQuery({
    String? search,
    String? category,
    String? instituteId,
    required int page,
    required int limit,
  }) {
    return {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (instituteId != null && instituteId.isNotEmpty)
        'instituteId': instituteId,
      'page': page,
      'limit': limit,
    };
  }

  CoursesResponse _parseCourses(Map<String, dynamic> response) {
    final coursesJson = response['data'];
    final paginationJson = response['pagination'];
    if (coursesJson is! List || paginationJson is! Map<String, dynamic>) {
      throw const FormatException('بيانات الدورات الواردة من الخادم غير صالحة');
    }
    return CoursesResponse(
      courses: coursesJson.map((course) {
        if (course is! Map<String, dynamic>) {
          throw const FormatException('بيانات إحدى الدورات غير صالحة');
        }
        return CourseModel.fromJson(course);
      }).toList(),
      pagination: CoursePaginationModel.fromJson(paginationJson),
    );
  }

  Future<CourseModel?> getCachedCourseDetails(String courseId) async {
    final cache = _publicCache;
    if (cache == null) return null;
    final key = cache.keyFor('/api/courses/$courseId', const {});
    final cached = await cache.read(key);
    if (cached == null) return null;
    return _parseCourseDetails(cached.data);
  }

  Future<PublicDataResult<CourseModel>> loadPublicCourseDetails(
    String courseId, {
    bool forceRefresh = false,
  }) async {
    final cache = _publicCache;
    final path = '/api/courses/$courseId';
    if (cache == null) {
      final response = await _apiClient.get(path);
      return PublicDataResult(
        data: _parseCourseDetails(response),
        changed: true,
      );
    }

    final key = cache.keyFor(path, const {});
    final result = await cache.fetchJson(
      key: key,
      ttl: _courseDetailsTtl,
      forceRefresh: forceRefresh,
      fetch: (etag) async {
        final response = await _apiClient.getPublic(path, ifNoneMatch: etag);
        if (!response.notModified) {
          final data = response.data;
          if (data == null) {
            throw const FormatException('بيانات الدورة الواردة غير صالحة');
          }
          _parseCourseDetails(data);
        }
        return PublicCacheFetch(
          data: response.data,
          etag: response.etag,
          notModified: response.notModified,
        );
      },
    );
    return PublicDataResult(
      data: _parseCourseDetails(result.data),
      changed: result.changed,
    );
  }

  CourseModel _parseCourseDetails(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('بيانات الدورة غير صالحة');
    }

    return CourseModel.fromJson(data);
  }

  Future<CourseModel> getCourseById(String courseId) async {
    final response = await _apiClient.get('/api/courses/$courseId');
    return _parseCourseDetails(response);
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
    bool requiresEnglishName = false,
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
        'requiresEnglishName': requiresEnglishName.toString(),
        'capacity': capacity.toString(),
        'startDate': SaudiDate.toApiDate(startDate),
        'endDate': SaudiDate.toApiDate(endDate),
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

  Future<CourseModel> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String category,
    required double price,
    required double depositAmount,
    bool requiresEnglishName = false,
    required int capacity,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required List<String> whatWillLearn,
    required List<String> features,
    String? image,
    List<int>? imageBytes,
    String? imageName,
    String? imageContentType,
  }) async {
    final response = await _apiClient.putMultipart(
      '/api/institutes/me/courses/$courseId',
      authenticated: true,
      fields: {
        'title': title,
        'description': description,
        'category': category,
        'price': price.toString(),
        'depositAmount': depositAmount.toString(),
        'requiresEnglishName': requiresEnglishName.toString(),
        'capacity': capacity.toString(),
        'startDate': SaudiDate.toApiDate(startDate),
        'endDate': SaudiDate.toApiDate(endDate),
        'location': location,
        'whatWillLearn': jsonEncode(whatWillLearn),
        'features': jsonEncode(features),
        'image': ?image,
      },
      fileBytes: imageBytes,
      fileField: imageBytes == null ? null : 'image',
      fileName: imageName,
      contentType: imageContentType,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات الدورة المعدلة');
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

  Future<CourseModel> reopenCourse(String courseId) async {
    final response = await _apiClient.patch(
      '/api/institutes/me/courses/$courseId/reopen',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات الدورة بعد إعادة الفتح');
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

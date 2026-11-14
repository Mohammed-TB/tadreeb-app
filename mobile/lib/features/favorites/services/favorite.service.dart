import '../../../core/network/api_client.dart';
import '../models/favorite.model.dart';
import '../../courses/models/course_model.dart';
import '../../institutes/models/institute_model.dart';

class FavoriteService {
  FavoriteService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CourseModel>> getFavoriteCourses() async {
    final data = await _getFavorites(FavoriteTargetType.course);
    return data.map(CourseModel.fromJson).toList();
  }

  Future<List<InstituteModel>> getFavoriteInstitutes() async {
    final data = await _getFavorites(FavoriteTargetType.institute);
    return data.map(InstituteModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _getFavorites(
    FavoriteTargetType type,
  ) async {
    final response = await _apiClient.get(
      '/api/favorites',
      queryParameters: {'type': type.name},
      authenticated: true,
    );
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('استجابة المفضلة غير صالحة');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('عنصر المفضلة غير صالح');
      }
      return item;
    }).toList();
  }

  Future<FavoriteModel> addFavorite(
    FavoriteTargetType type,
    String targetId,
  ) async {
    final response = await _apiClient.post(
      '/api/favorites/${type.name}',
      body: {'targetId': targetId},
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة بيانات المفضلة');
    }
    return FavoriteModel.fromJson(data);
  }

  Future<void> removeFavorite(
    FavoriteTargetType type,
    String targetId,
  ) async {
    await _apiClient.delete(
      '/api/favorites/${type.name}/$targetId',
      authenticated: true,
    );
  }
}
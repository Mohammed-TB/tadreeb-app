import '../../../core/network/api_client.dart';
import '../models/student_profile_model.dart';

class StudentProfileService {
  StudentProfileService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<StudentProfileModel> getProfile() async {
    final response = await _apiClient.get(
      '/api/students/me',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر قراءة ملف الطالب');
    }
    return StudentProfileModel.fromJson(data);
  }

  Future<StudentProfileModel> updateProfile({
    required String name,
    String? englishName,
  }) async {
    final response = await _apiClient.patch(
      '/api/students/me',
      authenticated: true,
      body: {'name': name, 'englishName': englishName ?? ''},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر حفظ ملف الطالب');
    }
    return StudentProfileModel.fromJson(data);
  }
}

import '../../../core/network/api_client.dart';
import '../models/admin_user_model.dart';

class AdminUserService {
  AdminUserService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AdminUserPage> getUsers({required int page}) async {
    final response = await _apiClient.get(
      '/api/admin/users',
      queryParameters: {'page': page, 'limit': 25},
      authenticated: true,
    );
    return AdminUserPage.fromJson(response);
  }

  Future<void> suspendUser({required String userId}) async {
    final response = await _apiClient.patch(
      '/api/admin/users/${Uri.encodeComponent(userId)}/suspend',
      authenticated: true,
    );
    final data = response['data'];
    final user = data is Map<String, dynamic> ? data['user'] : null;
    if (user is! Map<String, dynamic> ||
        user['id'] != userId ||
        user['status'] != AdminUserStatus.suspended.name) {
      throw const FormatException('Invalid user suspension response');
    }
  }
}

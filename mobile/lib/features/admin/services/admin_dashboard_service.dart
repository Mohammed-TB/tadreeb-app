import '../../../core/network/api_client.dart';
import '../models/admin_dashboard_stats.dart';

class AdminDashboardService {
  AdminDashboardService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AdminDashboardStats> getStats() async {
    final response = await _apiClient.get(
      '/api/admin/stats',
      authenticated: true,
    );
    return AdminDashboardStats.fromJson(response);
  }
}

import '../../../core/network/api_client.dart';
import '../models/institute_dashboard_model.dart';

class InstituteDashboardService {
  InstituteDashboardService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<InstituteDashboardData> getDashboard() async {
    final response = await _apiClient.get(
      '/api/institutes/me/dashboard',
      authenticated: true,
    );
    return InstituteDashboardData.fromJson(response);
  }
}

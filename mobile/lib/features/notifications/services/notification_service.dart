import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<({List<AppNotificationModel> items, int unreadCount})> getAll({
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      '/api/notifications',
      queryParameters: {'page': page, 'limit': 30},
      authenticated: true,
    );
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('بيانات الإشعارات غير صالحة');
    }
    return (
      items: data
          .whereType<Map>()
          .map((item) =>
              AppNotificationModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      unreadCount: response['unreadCount'] is int
          ? response['unreadCount'] as int
          : 0,
    );
  }

  Future<void> markRead(String recipientId) async {
    await _apiClient.patch(
      '/api/notifications/$recipientId/read',
      authenticated: true,
    );
  }

  Future<void> markAllRead() async {
    await _apiClient.patch(
      '/api/notifications/read-all',
      authenticated: true,
    );
  }
}

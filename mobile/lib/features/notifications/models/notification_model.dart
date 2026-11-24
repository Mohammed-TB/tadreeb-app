class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String notificationId;
  final String type;
  final String title;
  final String body;
  final String entityType;
  final String entityId;
  final String action;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      notificationId: json['notificationId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

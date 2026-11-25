import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(
    this._service, {
    RealtimeService? realtimeService,
  }) {
    _subscription = realtimeService?.events.listen(_onRealtimeEvent);
  }

  final NotificationService _service;
  StreamSubscription<RealtimeEvent>? _subscription;

  List<AppNotificationModel> _items = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<AppNotificationModel> get items => _items;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onRealtimeEvent(RealtimeEvent event) {
    if (event.name == 'notificationCreated') {
      unawaited(fetch(forceRefresh: true));
    }
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.getAll();
      _items = result.items;
      _unreadCount = result.unreadCount;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotificationModel notification) async {
    if (!notification.isRead) {
      await _service.markRead(notification.id);
      final index = _items.indexWhere((item) => item.id == notification.id);
      if (index != -1) {
        _items[index] = AppNotificationModel(
          id: notification.id,
          notificationId: notification.notificationId,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          entityType: notification.entityType,
          entityId: notification.entityId,
          action: notification.action,
          isRead: true,
          createdAt: notification.createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 999999).toInt();
        notifyListeners();
      }
    }
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    _items = _items
        .map((item) => AppNotificationModel(
              id: item.id,
              notificationId: item.notificationId,
              type: item.type,
              title: item.title,
              body: item.body,
              entityType: item.entityType,
              entityId: item.entityId,
              action: item.action,
              isRead: true,
              createdAt: item.createdAt,
            ))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

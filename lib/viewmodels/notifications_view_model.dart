import 'dart:async';

import '../models/app_notification.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

class NotificationsViewModel extends BaseViewModel {
  NotificationsViewModel(this._services, this.userId) {
    _subscription = _services.data
        .watchNotifications(userId)
        .listen((List<AppNotification> notifications) {
      _notifications = notifications;
      _loading = false;
      safeNotify();
    }, onError: (Object error) {
      setError('errorGeneric');
      _loading = false;
      safeNotify();
    });
  }

  final Services _services;
  final String userId;

  StreamSubscription<List<AppNotification>>? _subscription;
  List<AppNotification> _notifications = const <AppNotification>[];
  bool _loading = true;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount => _notifications
      .where((AppNotification notification) => !notification.read)
      .length;

  Future<void> markAllRead() => _services.data.markNotificationsRead(userId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

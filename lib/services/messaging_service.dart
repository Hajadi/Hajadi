import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push notifications.
///
/// Payloads carry a catalog key plus arguments (never rendered text), so a
/// notification sent last week still renders in whatever language the user
/// reads today.
abstract class MessagingService {
  /// Requests permission and returns the device token, or null when push is
  /// unavailable or refused.
  Future<String?> initialize();

  /// Emits the `data` payload of a notification the user tapped.
  Stream<Map<String, String>> get onNotificationTap;

  Future<void> subscribeToRole(String role);

  Future<void> unsubscribeFromRole(String role);

  void dispose();
}

class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final StreamController<Map<String, String>> _taps =
      StreamController<Map<String, String>>.broadcast();

  @override
  Stream<Map<String, String>> get onNotificationTap => _taps.stream;

  static Map<String, String> _data(RemoteMessage message) => message.data.map(
        (String key, dynamic value) => MapEntry<String, String>(key, '$value'),
      );

  @override
  Future<String?> initialize() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) => _taps.add(_data(message)),
    );

    final RemoteMessage? initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _taps.add(_data(initial));
    }

    try {
      return await _messaging.getToken();
    } catch (error) {
      debugPrint('FCM token unavailable: $error');
      return null;
    }
  }

  @override
  Future<void> subscribeToRole(String role) =>
      _messaging.subscribeToTopic('role_$role');

  @override
  Future<void> unsubscribeFromRole(String role) =>
      _messaging.unsubscribeFromTopic('role_$role');

  @override
  void dispose() => _taps.close();
}

/// No-op implementation for demo mode and for platforms without FCM.
class DemoMessagingService implements MessagingService {
  @override
  Stream<Map<String, String>> get onNotificationTap =>
      const Stream<Map<String, String>>.empty();

  @override
  Future<String?> initialize() async => null;

  @override
  Future<void> subscribeToRole(String role) async {}

  @override
  Future<void> unsubscribeFromRole(String role) async {}

  @override
  void dispose() {}
}

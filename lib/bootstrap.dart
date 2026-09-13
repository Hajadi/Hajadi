import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'core/config/app_config.dart';

/// Handles notifications that arrive while the app is terminated or in the
/// background. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background notification: ${message.messageId}');
}

/// Initializes Firebase and turns on offline persistence.
///
/// Returns false when no Firebase project is wired up yet, which is what puts
/// the app into demo mode.
Future<bool> initializeFirebase() async {
  if (AppConfig.demoMode) {
    return false;
  }
  try {
    await Firebase.initializeApp();

    // Offline-first: Firestore serves reads from its local cache when the
    // network is unavailable, and replays writes once it returns.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
    return true;
  } catch (error, stack) {
    debugPrint('Firebase init failed, falling back to demo mode: $error');
    debugPrintStack(stackTrace: stack);
    return false;
  }
}

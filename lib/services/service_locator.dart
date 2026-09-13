import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import 'auth_service.dart';
import 'data_service.dart';
import 'demo_auth_service.dart';
import 'demo_data_service.dart';
import 'firebase_auth_service.dart';
import 'firestore_data_service.dart';
import 'location_service.dart';
import 'messaging_service.dart';
import 'payment_service.dart';
import 'preferences_service.dart';
import 'storage_service.dart';

/// The one place that decides whether the app talks to Firebase or to the
/// bundled sample data. Everything downstream depends on interfaces only.
class Services {
  Services({
    required this.preferences,
    required this.auth,
    required this.data,
    required this.storage,
    required this.payments,
    required this.messaging,
    required this.location,
    required this.demoMode,
  });

  final PreferencesService preferences;
  final AuthService auth;
  final DataService data;
  final StorageService storage;
  final PaymentService payments;
  final MessagingService messaging;
  final LocationService location;
  final bool demoMode;

  /// [firebaseReady] is false when `Firebase.initializeApp` failed or no
  /// `firebase_options.dart` was generated — in that case we fall back to demo
  /// mode rather than crashing on first read.
  static Future<Services> create({required bool firebaseReady}) async {
    final PreferencesService preferences = await PreferencesService.create();
    final bool demo = AppConfig.demoMode || !firebaseReady;

    if (demo) {
      debugPrint(
        'Jwenn Mèt is running in demo mode — data comes from '
        'assets/sample_data. Build with --dart-define=DEMO_MODE=false once '
        'Firebase is configured.',
      );
      return Services(
        preferences: preferences,
        auth: DemoAuthService(preferences),
        data: DemoDataService(),
        storage: DemoStorageService(),
        payments: DemoPaymentService(),
        messaging: DemoMessagingService(),
        location: LocationService(),
        demoMode: true,
      );
    }

    return Services(
      preferences: preferences,
      auth: FirebaseAuthService(),
      data: FirestoreDataService(),
      storage: FirebaseStorageService(),
      payments: HttpPaymentService(),
      messaging: FirebaseMessagingService(),
      location: LocationService(),
      demoMode: false,
    );
  }
}

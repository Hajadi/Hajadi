import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase is optional at boot: without a generated firebase_options.dart
  // (or with a failing init) the app falls back to bundled sample data instead
  // of showing a crash screen.
  final bool firebaseReady = await initializeFirebase();
  final Services services = await Services.create(firebaseReady: firebaseReady);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught framework error: ${details.exception}');
  };

  runApp(JwennMetApp(services: services));
}

/// Build-time configuration.
///
/// Nothing secret lives here: Firebase keys come from the generated
/// `firebase_options.dart`, payment credentials stay server-side in Cloud
/// Functions. Override any value with `--dart-define`.
abstract final class AppConfig {
  /// When true the app runs entirely on bundled sample data — no Firebase
  /// project needed. This is what `flutter run` uses out of the box so the
  /// app is explorable before any backend is provisioned.
  static const bool demoMode =
      bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  static const String appVersion = '1.0.0';

  /// Platform-wide commission applied to each invoice (10%).
  static const double serviceFeeRate = 0.10;

  /// Haiti's national police emergency line.
  static const String emergencyNumber = '114';

  static const String supportEmail = 'support@jwennmet.ht';

  /// Default map camera: Port-au-Prince.
  static const double defaultLatitude = 18.5944;
  static const double defaultLongitude = -72.3074;

  /// Search radius bounds in kilometres.
  static const double minDistanceKm = 1;
  static const double maxDistanceKm = 100;

  /// Hourly-rate bounds in gourdes, used by the price filter.
  static const double minHourlyRate = 0;
  static const double maxHourlyRate = 5000;

  /// Cloud Function endpoints that broker MonCash / NatCash / card payments.
  static const String paymentsBaseUrl = String.fromEnvironment(
    'PAYMENTS_BASE_URL',
    defaultValue: 'https://us-central1-jwenn-met.cloudfunctions.net',
  );

  /// Card acquirer's tokenization endpoint and publishable key.
  ///
  /// Set both to accept cards with an in-app form: the number goes straight
  /// from the device to the provider and only the resulting token reaches our
  /// backend. Leave them empty and card payments fall back to the provider's
  /// hosted checkout page, where no card data touches the app at all. Either
  /// way the secret key stays in Cloud Functions.
  static const String cardTokenizationUrl = String.fromEnvironment(
    'CARD_TOKENIZATION_URL',
  );
  static const String cardPublishableKey = String.fromEnvironment(
    'CARD_PUBLISHABLE_KEY',
  );
}

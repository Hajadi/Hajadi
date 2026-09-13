import 'package:geolocator/geolocator.dart';

import '../core/config/app_config.dart';

class LatLngPoint {
  const LatLngPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Wraps geolocation so the rest of the app never has to think about
/// permissions — a denied prompt simply means "use Port-au-Prince".
class LocationService {
  static const LatLngPoint fallback = LatLngPoint(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );

  LatLngPoint? _lastKnown;

  LatLngPoint? get lastKnown => _lastKnown;

  Future<LatLngPoint?> current({bool requestPermission = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _lastKnown;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _lastKnown;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return _lastKnown = LatLngPoint(position.latitude, position.longitude);
    } catch (_) {
      // Timeouts and platform errors are not worth surfacing: search just
      // falls back to department-level filtering.
      return _lastKnown;
    }
  }
}

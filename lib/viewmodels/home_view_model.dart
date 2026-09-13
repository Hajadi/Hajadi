import '../core/constants/service_categories.dart';
import '../models/search_filters.dart';
import '../models/worker_profile.dart';
import '../services/location_service.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Feeds the home screen: three curated shelves plus the category grid.
class HomeViewModel extends BaseViewModel {
  HomeViewModel(this._services) {
    load();
  }

  final Services _services;

  List<WorkerProfile> _topRated = const <WorkerProfile>[];
  List<WorkerProfile> _nearby = const <WorkerProfile>[];
  List<WorkerProfile> _verified = const <WorkerProfile>[];
  LatLngPoint? _position;

  List<WorkerProfile> get topRated => _topRated;
  List<WorkerProfile> get nearby => _nearby;
  List<WorkerProfile> get verified => _verified;
  LatLngPoint? get position => _position;
  List<ServiceCategory> get categories => ServiceCategory.values;

  Future<void> load() async {
    await guard(() async {
      // Location is a nice-to-have: the shelves still render without it.
      _position = await _services.location.current(requestPermission: false);

      _topRated = await _services.data.searchWorkers(
        const SearchFilters(minRating: 4.5),
        limit: 10,
        originLatitude: _position?.latitude,
        originLongitude: _position?.longitude,
      );
      _verified = await _services.data.searchWorkers(
        const SearchFilters(verifiedOnly: true, availableNow: true),
        limit: 10,
        originLatitude: _position?.latitude,
        originLongitude: _position?.longitude,
      );
      _nearby = _position == null
          ? const <WorkerProfile>[]
          : await _services.data.searchWorkers(
              const SearchFilters(sort: WorkerSort.distance, maxDistanceKm: 25),
              limit: 10,
              originLatitude: _position!.latitude,
              originLongitude: _position!.longitude,
            );

      // Cache the top shelf so a cold start with no network still has content.
      await _services.preferences.writeCache(
        'home.topRated',
        _topRated.map((WorkerProfile w) => w.toMap()..['id'] = w.id).toList(),
      );
      return true;
    });
    safeNotify();
  }

  /// Rehydrates the cached shelf — used when [load] fails offline.
  void restoreFromCache() {
    final List<Map<String, dynamic>> cached =
        _services.preferences.readCachedList('home.topRated');
    if (cached.isEmpty) {
      return;
    }
    _topRated = cached
        .map(
          (Map<String, dynamic> map) =>
              WorkerProfile.fromMap('${map['id']}', map),
        )
        .toList();
    safeNotify();
  }
}

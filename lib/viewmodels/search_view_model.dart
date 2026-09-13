import 'dart:async';

import '../models/search_filters.dart';
import '../models/worker_profile.dart';
import '../services/location_service.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Owns the filter state and the debounced query behind the search screen.
class SearchViewModel extends BaseViewModel {
  SearchViewModel(this._services, {SearchFilters? initialFilters}) {
    _filters = initialFilters ?? const SearchFilters();
    search();
  }

  final Services _services;

  late SearchFilters _filters;
  List<WorkerProfile> _results = const <WorkerProfile>[];
  Timer? _debounce;
  LatLngPoint? _position;

  SearchFilters get filters => _filters;
  List<WorkerProfile> get results => _results;
  bool get isEmpty => !busy && _results.isEmpty;

  void updateQuery(String query) {
    _filters = _filters.copyWith(query: query);
    safeNotify();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), search);
  }

  /// Applies a whole filter set at once (the filter sheet's "Apply" button).
  void applyFilters(SearchFilters filters) {
    _filters = filters;
    safeNotify();
    search();
  }

  void resetFilters() {
    _filters = SearchFilters(query: _filters.query);
    safeNotify();
    search();
  }

  void setSort(WorkerSort sort) {
    _filters = _filters.copyWith(sort: sort);
    safeNotify();
    search();
  }

  Future<void> search() async {
    await guard(() async {
      // Distance sorting and the radius filter both need a position; asking
      // only when it matters keeps the permission prompt honest.
      if (_position == null &&
          (_filters.usesDistance || _filters.sort == WorkerSort.distance)) {
        _position = await _services.location.current();
      }
      _results = await _services.data.searchWorkers(
        _filters,
        originLatitude: _position?.latitude,
        originLongitude: _position?.longitude,
      );
      return true;
    });
    safeNotify();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

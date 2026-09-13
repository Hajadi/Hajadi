import '../core/config/app_config.dart';

enum WorkerSort { rating, price, distance }

/// The complete filter state behind the search screen. Immutable so the
/// view-model can diff it and only re-query when something really changed.
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.categoryId,
    this.departmentId,
    this.city,
    this.maxDistanceKm = AppConfig.maxDistanceKm,
    this.minPrice = AppConfig.minHourlyRate,
    this.maxPrice = AppConfig.maxHourlyRate,
    this.minRating = 0,
    this.verifiedOnly = false,
    this.availableNow = false,
    this.sort = WorkerSort.rating,
  });

  final String query;
  final String? categoryId;
  final String? departmentId;
  final String? city;
  final double maxDistanceKm;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool verifiedOnly;
  final bool availableNow;
  final WorkerSort sort;

  bool get usesDistance => maxDistanceKm < AppConfig.maxDistanceKm;

  /// How many filters are visibly narrowing the result set — drives the badge
  /// on the filter button.
  int get activeCount {
    int count = 0;
    if (categoryId != null) count++;
    if (departmentId != null) count++;
    if (city != null) count++;
    if (usesDistance) count++;
    if (minPrice > AppConfig.minHourlyRate ||
        maxPrice < AppConfig.maxHourlyRate) {
      count++;
    }
    if (minRating > 0) count++;
    if (verifiedOnly) count++;
    if (availableNow) count++;
    return count;
  }

  SearchFilters copyWith({
    String? query,
    Object? categoryId = _unset,
    Object? departmentId = _unset,
    Object? city = _unset,
    double? maxDistanceKm,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? verifiedOnly,
    bool? availableNow,
    WorkerSort? sort,
  }) =>
      SearchFilters(
        query: query ?? this.query,
        categoryId: categoryId == _unset
            ? this.categoryId
            : categoryId as String?,
        departmentId: departmentId == _unset
            ? this.departmentId
            : departmentId as String?,
        city: city == _unset ? this.city : city as String?,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minRating: minRating ?? this.minRating,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        availableNow: availableNow ?? this.availableNow,
        sort: sort ?? this.sort,
      );

  static const Object _unset = Object();
}

import '../../models/search_filters.dart';
import '../../models/worker_profile.dart';
import '../constants/service_categories.dart';
import 'geo.dart';

/// Client-side half of worker search.
///
/// Firestore handles the indexed predicates (category, availability,
/// verification); free text, price, city, distance and the final ordering run
/// here so the same rules apply to cached results and to demo data.
abstract final class WorkerQuery {
  static List<WorkerProfile> apply(
    List<WorkerProfile> source,
    SearchFilters filters, {
    double? originLatitude,
    double? originLongitude,
  }) {
    // Folded once: the same accent- and case-insensitive form every trade
    // name is compared in, so "Électricien" and "electricien" both land.
    final String needle = TradeText.fold(filters.query);

    final List<WorkerProfile> result = <WorkerProfile>[];
    for (final WorkerProfile worker in source) {
      if (worker.suspended) {
        continue;
      }
      if (filters.categoryId != null &&
          !worker.categoryIds.contains(filters.categoryId)) {
        continue;
      }
      if (filters.departmentId != null &&
          worker.departmentId != filters.departmentId &&
          !worker.serviceDepartmentIds.contains(filters.departmentId)) {
        continue;
      }
      if (filters.city != null &&
          worker.city != filters.city &&
          !worker.serviceCities.contains(filters.city)) {
        continue;
      }
      if (filters.verifiedOnly && !worker.isVerified) {
        continue;
      }
      if (filters.availableNow && !worker.availableNow) {
        continue;
      }
      if (worker.rating < filters.minRating) {
        continue;
      }
      if (worker.hourlyRate < filters.minPrice ||
          worker.hourlyRate > filters.maxPrice) {
        continue;
      }
      if (needle.isNotEmpty && !_matchesText(worker, needle)) {
        continue;
      }

      double? distance;
      if (originLatitude != null &&
          originLongitude != null &&
          worker.latitude != null &&
          worker.longitude != null) {
        distance = Geo.distanceKm(
          originLatitude,
          originLongitude,
          worker.latitude!,
          worker.longitude!,
        );
        if (filters.usesDistance && distance > filters.maxDistanceKm) {
          continue;
        }
      }
      result.add(worker.copyWith(distanceKm: distance));
    }

    result.sort((WorkerProfile a, WorkerProfile b) => switch (filters.sort) {
          WorkerSort.rating => _byRating(a, b),
          WorkerSort.price => a.hourlyRate.compareTo(b.hourlyRate),
          WorkerSort.distance => (a.distanceKm ?? double.maxFinite)
              .compareTo(b.distanceKm ?? double.maxFinite),
        });
    return result;
  }

  /// Free text matches the worker's own words, the trades they picked — in any
  /// of the three languages, so "plonbye" finds a plumber — and any trade they
  /// typed themselves.
  static bool _matchesText(WorkerProfile worker, String needle) =>
      TradeText.fold(worker.fullName).contains(needle) ||
      TradeText.fold(worker.headline).contains(needle) ||
      TradeText.fold(worker.bio).contains(needle) ||
      TradeText.fold(worker.city).contains(needle) ||
      worker.customCategories
          .any((String trade) => TradeText.fold(trade).contains(needle)) ||
      worker.categoryIds.any((String id) {
        final ServiceCategory? category = ServiceCategory.fromId(id);
        return category == null
            ? TradeText.fold(id).contains(needle)
            : category.matchesNeedle(needle);
      });

  /// Rating first, then review volume — a lone 5★ should not outrank a
  /// worker with fifty reviews at 4.8★.
  static int _byRating(WorkerProfile a, WorkerProfile b) {
    final int byRating = b.rating.compareTo(a.rating);
    return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
  }
}

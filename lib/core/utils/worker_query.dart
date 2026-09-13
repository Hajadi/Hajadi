import '../../models/search_filters.dart';
import '../../models/worker_profile.dart';
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
    final String needle = filters.query.trim().toLowerCase();

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

  static bool _matchesText(WorkerProfile worker, String needle) =>
      worker.fullName.toLowerCase().contains(needle) ||
      worker.headline.toLowerCase().contains(needle) ||
      worker.bio.toLowerCase().contains(needle) ||
      worker.city.toLowerCase().contains(needle) ||
      worker.categoryIds
          .any((String id) => id.replaceAll('_', ' ').contains(needle));

  /// Rating first, then review volume — a lone 5★ should not outrank a
  /// worker with fifty reviews at 4.8★.
  static int _byRating(WorkerProfile a, WorkerProfile b) {
    final int byRating = b.rating.compareTo(a.rating);
    return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
  }
}

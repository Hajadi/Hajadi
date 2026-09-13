import 'package:flutter_test/flutter_test.dart';
import 'package:jwenn_met/core/utils/worker_query.dart';
import 'package:jwenn_met/models/search_filters.dart';
import 'package:jwenn_met/models/worker_profile.dart';

WorkerProfile worker({
  required String id,
  List<String> categories = const <String>['electrician'],
  String department = 'ouest',
  String city = 'Delmas',
  double rate = 500,
  double rating = 4.5,
  int reviews = 10,
  bool verified = true,
  bool available = true,
  bool suspended = false,
  double? latitude,
  double? longitude,
  List<String> serviceDepartments = const <String>[],
  List<String> serviceCities = const <String>[],
}) =>
    WorkerProfile(
      id: id,
      fullName: 'Bòs $id',
      categoryIds: categories,
      departmentId: department,
      city: city,
      hourlyRate: rate,
      rating: rating,
      reviewCount: reviews,
      verification:
          verified ? VerificationStatus.approved : VerificationStatus.unverified,
      availableNow: available,
      suspended: suspended,
      latitude: latitude,
      longitude: longitude,
      serviceDepartmentIds: serviceDepartments,
      serviceCities: serviceCities,
    );

void main() {
  group('WorkerQuery.apply', () {
    test('keeps only the requested category', () {
      final List<WorkerProfile> result = WorkerQuery.apply(
        <WorkerProfile>[
          worker(id: 'a'),
          worker(id: 'b', categories: <String>['plumber']),
        ],
        const SearchFilters(categoryId: 'plumber'),
      );
      expect(result.map((WorkerProfile w) => w.id), <String>['b']);
    });

    test('matches a department through the service areas, not just the home one',
        () {
      final List<WorkerProfile> result = WorkerQuery.apply(
        <WorkerProfile>[
          worker(id: 'a', department: 'nord'),
          worker(
            id: 'b',
            department: 'nord',
            serviceDepartments: <String>['artibonite'],
          ),
        ],
        const SearchFilters(departmentId: 'artibonite'),
      );
      expect(result.map((WorkerProfile w) => w.id), <String>['b']);
    });

    test('drops suspended accounts whatever else matches', () {
      final List<WorkerProfile> result = WorkerQuery.apply(
        <WorkerProfile>[worker(id: 'a', suspended: true)],
        const SearchFilters(),
      );
      expect(result, isEmpty);
    });

    test('applies the price window inclusively', () {
      final List<WorkerProfile> result = WorkerQuery.apply(
        <WorkerProfile>[
          worker(id: 'cheap', rate: 300),
          worker(id: 'edge', rate: 500),
          worker(id: 'pricey', rate: 900),
        ],
        const SearchFilters(minPrice: 500, maxPrice: 800),
      );
      expect(result.map((WorkerProfile w) => w.id), <String>['edge']);
    });

    test('verified-only and available-now narrow independently', () {
      final List<WorkerProfile> source = <WorkerProfile>[
        worker(id: 'a', verified: false, available: true),
        worker(id: 'b', verified: true, available: false),
        worker(id: 'c', verified: true, available: true),
      ];
      expect(
        WorkerQuery.apply(source, const SearchFilters(verifiedOnly: true))
            .map((WorkerProfile w) => w.id),
        <String>['b', 'c'],
      );
      expect(
        WorkerQuery.apply(source, const SearchFilters(availableNow: true))
            .map((WorkerProfile w) => w.id),
        <String>['a', 'c'],
      );
    });

    test('free text looks at name, city and trade', () {
      final List<WorkerProfile> source = <WorkerProfile>[
        worker(id: 'a', city: 'Jacmel'),
        worker(id: 'b', categories: <String>['ac_technician']),
      ];
      expect(
        WorkerQuery.apply(source, const SearchFilters(query: 'jacmel'))
            .map((WorkerProfile w) => w.id),
        <String>['a'],
      );
      expect(
        WorkerQuery.apply(source, const SearchFilters(query: 'ac tech'))
            .map((WorkerProfile w) => w.id),
        <String>['b'],
      );
    });

    test('computes distance and honours the radius', () {
      // Port-au-Prince to Pétion-Ville is roughly 7 km.
      final List<WorkerProfile> source = <WorkerProfile>[
        worker(id: 'near', latitude: 18.5125, longitude: -72.2853),
        worker(id: 'far', latitude: 19.7579, longitude: -72.2043), // Cap-Haïtien
      ];
      final List<WorkerProfile> result = WorkerQuery.apply(
        source,
        const SearchFilters(maxDistanceKm: 25),
        originLatitude: 18.5944,
        originLongitude: -72.3074,
      );
      expect(result.map((WorkerProfile w) => w.id), <String>['near']);
      expect(result.single.distanceKm, lessThan(25));
    });

    test('rating sort breaks ties on review volume', () {
      final List<WorkerProfile> result = WorkerQuery.apply(
        <WorkerProfile>[
          worker(id: 'thin', rating: 5, reviews: 1),
          worker(id: 'proven', rating: 5, reviews: 60),
          worker(id: 'good', rating: 4.8, reviews: 200),
        ],
        const SearchFilters(),
      );
      expect(
        result.map((WorkerProfile w) => w.id),
        <String>['proven', 'thin', 'good'],
      );
    });

    test('price sort is ascending', () {
      final List<WorkerProfile> result = WorkerQuery.apply(
        <WorkerProfile>[
          worker(id: 'b', rate: 900),
          worker(id: 'a', rate: 350),
        ],
        const SearchFilters(sort: WorkerSort.price),
      );
      expect(result.map((WorkerProfile w) => w.id), <String>['a', 'b']);
    });
  });

  test('activeCount counts only narrowing filters', () {
    expect(const SearchFilters().activeCount, 0);
    expect(
      const SearchFilters(categoryId: 'mason', verifiedOnly: true).activeCount,
      2,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jwenn_met/core/constants/service_categories.dart';

/// The trade catalog is what a worker picks from and what a job is filed
/// under, so its ids, its groups and the rules around a typed trade all have
/// to hold — a stored id that stops resolving orphans every document using it.
void main() {
  group('catalog', () {
    test('every id is unique and resolves', () {
      final Set<String> ids =
          ServiceCategory.values.map((ServiceCategory c) => c.id).toSet();
      expect(ids.length, ServiceCategory.values.length);
      for (final ServiceCategory category in ServiceCategory.values) {
        expect(ServiceCategory.fromId(category.id), category);
      }
    });

    test('every trade belongs to exactly one group, and groups cover them all',
        () {
      final List<ServiceCategory> grouped = TradeGroup.values
          .expand((TradeGroup group) => group.categories)
          .toList();
      expect(grouped.toSet(), ServiceCategory.values.toSet());
      expect(grouped.length, ServiceCategory.values.length);
    });

    test('`listed` is everything a customer can browse — all but `other`', () {
      expect(ServiceCategory.listed, isNot(contains(ServiceCategory.other)));
      expect(ServiceCategory.listed.length, ServiceCategory.values.length - 1);
    });

    test('aliases are stored folded, or matching silently stops working', () {
      for (final ServiceCategory category in ServiceCategory.values) {
        for (final String alias in category.aliases) {
          expect(TradeText.fold(alias), alias, reason: '${category.id}: $alias');
        }
      }
    });

    test('no alias is claimed by two trades', () {
      final Map<String, ServiceCategory> seen = <String, ServiceCategory>{};
      for (final ServiceCategory category in ServiceCategory.values) {
        for (final String alias in category.aliases) {
          expect(
            seen[alias],
            isNull,
            reason: '"$alias" is on both ${seen[alias]?.id} and ${category.id}',
          );
          seen[alias] = category;
        }
      }
    });
  });

  group('TradeText.fold', () {
    test('strips case, accents and separators', () {
      expect(TradeText.fold('  Électricien  '), 'electricien');
      expect(TradeText.fold('AC_Technician'), 'ac technician');
      expect(TradeText.fold('Teknisyen   AC'), 'teknisyen ac');
      expect(TradeText.fold('Kwafè'), 'kwafe');
    });
  });

  group('ServiceCategory.match', () {
    test('recognises a listed trade however it was typed', () {
      expect(ServiceCategory.match('Coiffeuse'), ServiceCategory.hairStylist);
      expect(ServiceCategory.match('kwafe'), ServiceCategory.hairStylist);
      expect(ServiceCategory.match('MASSAGE'), ServiceCategory.massageTherapist);
      expect(ServiceCategory.match('makiyaj'), ServiceCategory.makeupArtist);
      expect(ServiceCategory.match('ac_technician'),
          ServiceCategory.acTechnician);
    });

    test('returns null for a trade we do not list — the custom-trade case', () {
      expect(ServiceCategory.match('Fotograf evènman'), isNull);
      expect(ServiceCategory.match('DJ'), isNull);
      expect(ServiceCategory.match('   '), isNull);
    });

    test('the word "Other" matches `other`, which names no trade', () {
      expect(ServiceCategory.match('Other'), ServiceCategory.other);
      expect(ServiceCategory.match('Lòt'), ServiceCategory.other);
      expect(ServiceCategory.match('autre'), ServiceCategory.other);
    });
  });

  group('CustomTrade', () {
    test('clean trims, collapses whitespace and caps the length', () {
      expect(CustomTrade.clean('  Fotograf   evènman '), 'Fotograf evènman');
      expect(CustomTrade.clean('   '), isNull);
      expect(CustomTrade.clean(''), isNull);
      expect(
        CustomTrade.clean('x' * (CustomTrade.maxLength + 20))!.length,
        CustomTrade.maxLength,
      );
    });

    test('duplicates are caught regardless of case and accents', () {
      const List<String> existing = <String>['Fotograf evènman'];
      expect(CustomTrade.isDuplicate('fotograf evenman', existing), isTrue);
      expect(CustomTrade.isDuplicate('FOTOGRAF EVÈNMAN', existing), isTrue);
      expect(CustomTrade.isDuplicate('DJ', existing), isFalse);
    });
  });
}

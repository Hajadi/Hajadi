import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the promise that every screen is fully translated: the three
/// catalogs must carry the same keys and the same placeholders.
void main() {
  Map<String, String> load(String code) {
    final String raw = File('assets/i18n/$code.json').readAsStringSync();
    return (json.decode(raw) as Map<String, dynamic>).map(
      (String key, dynamic value) => MapEntry<String, String>(key, '$value'),
    );
  }

  final Map<String, String> en = load('en');
  final Map<String, String> fr = load('fr');
  final Map<String, String> ht = load('ht');

  Set<String> placeholders(String value) =>
      RegExp(r'\{(\w+)\}').allMatches(value).map((Match m) => m.group(1)!).toSet();

  test('English catalog is not empty', () {
    expect(en.length, greaterThan(200));
  });

  for (final MapEntry<String, Map<String, String>> entry
      in <String, Map<String, String>>{'fr': fr, 'ht': ht}.entries) {
    test('${entry.key} has every English key, and no extras', () {
      expect(entry.value.keys.toSet(), en.keys.toSet());
    });

    test('${entry.key} keeps the same placeholders', () {
      for (final String key in en.keys) {
        expect(
          placeholders(entry.value[key]!),
          placeholders(en[key]!),
          reason: 'placeholder mismatch on "$key"',
        );
      }
    });

    test('${entry.key} has no blank translations', () {
      for (final MapEntry<String, String> pair in entry.value.entries) {
        expect(pair.value.trim(), isNotEmpty, reason: pair.key);
      }
    });
  }

  test('generated strings.dart is in sync with en.json', () {
    final String generated =
        File('lib/core/localization/strings.dart').readAsStringSync();
    for (final String key in en.keys) {
      expect(
        generated.contains("'$key'"),
        isTrue,
        reason: '$key is missing from strings.dart — run scripts/gen_strings.py',
      );
    }
  });
}

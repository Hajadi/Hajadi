/// Defensive readers for documents coming back from Firestore, the offline
/// cache or the bundled sample data — three sources with slightly different
/// notions of "a date" or "a number".
abstract final class Json {
  static String asString(Object? value, {String fallback = ''}) =>
      value is String ? value : (value == null ? fallback : '$value');

  static String? asStringOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    final String text = value is String ? value : '$value';
    return text.isEmpty ? null : text;
  }

  static double asDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static int asInt(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static bool asBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return fallback;
  }

  static List<String> asStringList(Object? value) {
    if (value is List) {
      return value.map((Object? e) => '$e').toList();
    }
    return const <String>[];
  }

  static List<Map<String, dynamic>> asMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<Object?, Object?>>()
          .map(Json.asMap)
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map) {
      return value.map(
        (Object? key, Object? v) => MapEntry<String, dynamic>('$key', v),
      );
    }
    return <String, dynamic>{};
  }

  /// Accepts a [DateTime], epoch milliseconds, an ISO-8601 string, or a
  /// Firestore `Timestamp` (duck-typed through `toDate()` so the models stay
  /// free of a `cloud_firestore` import).
  static DateTime? asDateOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    try {
      final dynamic converted = (value as dynamic).toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Not a Timestamp-like object; fall through.
    }
    return null;
  }

  static DateTime asDate(Object? value) =>
      asDateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

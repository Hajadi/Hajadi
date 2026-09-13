import 'package:intl/intl.dart';

/// Locale-aware money, date and distance formatting.
///
/// Gourde amounts are written `2,500 HTG` rather than with a currency symbol:
/// that is how prices are quoted in Haiti, in all three languages.
abstract final class Formatters {
  static String money(double amount, String localeCode, {String currency = 'HTG'}) {
    final NumberFormat format = NumberFormat.decimalPattern(localeCode)
      ..maximumFractionDigits = amount.truncateToDouble() == amount ? 0 : 2;
    return '${format.format(amount)} $currency';
  }

  static String compactNumber(num value, String localeCode) =>
      NumberFormat.compact(locale: localeCode).format(value);

  static String date(DateTime? date, String localeCode) => date == null
      ? '—'
      : DateFormat.yMMMd(_intlLocale(localeCode)).format(date.toLocal());

  static String dateTime(DateTime? date, String localeCode) => date == null
      ? '—'
      : DateFormat.yMMMd(_intlLocale(localeCode))
          .add_Hm()
          .format(date.toLocal());

  static String time(DateTime? date, String localeCode) => date == null
      ? ''
      : DateFormat.Hm(_intlLocale(localeCode)).format(date.toLocal());

  static String monthYear(DateTime? date, String localeCode) => date == null
      ? '—'
      : DateFormat.yMMM(_intlLocale(localeCode)).format(date.toLocal());

  static String distance(double? km) {
    if (km == null) {
      return '';
    }
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  static String rating(double value) => value.toStringAsFixed(1);

  /// `intl` has no Haitian Creole date symbols, so `ht` borrows French ones —
  /// the same fallback the widget localizations use.
  static String _intlLocale(String localeCode) =>
      localeCode == 'ht' ? 'fr' : localeCode;
}

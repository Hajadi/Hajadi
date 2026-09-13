/// Card brands Jwenn Mèt accepts.
///
/// Deliberately a short list: Visa and Mastercard are what Haitian issuers put
/// in customers' hands. Amex and Discover are recognised so an unsupported card
/// gets a clear "we don't take this" instead of a vague validation error.
enum CardBrand {
  visa('visa', 'Visa'),
  mastercard('mastercard', 'Mastercard'),
  amex('amex', 'American Express'),
  discover('discover', 'Discover'),
  unknown('unknown', 'Card');

  const CardBrand(this.id, this.label);

  final String id;
  final String label;

  bool get isAccepted =>
      this == CardBrand.visa || this == CardBrand.mastercard;

  static CardBrand fromId(String? id) {
    for (final CardBrand brand in CardBrand.values) {
      if (brand.id == id) {
        return brand;
      }
    }
    return CardBrand.unknown;
  }
}

/// Card number handling: brand detection, Luhn, formatting and expiry.
///
/// This runs on the device only to give immediate feedback and to stop an
/// obviously bad number from reaching the payment provider. The number itself
/// is never sent to our own backend — see [PaymentService].
abstract final class CardUtils {
  /// Digits only, spaces and dashes removed.
  static String digitsOf(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  /// Brand from the issuer identification number.
  static CardBrand brandOf(String number) {
    final String digits = digitsOf(number);
    if (digits.isEmpty) {
      return CardBrand.unknown;
    }
    if (digits.startsWith('4')) {
      return CardBrand.visa;
    }
    if (RegExp(r'^3[47]').hasMatch(digits)) {
      return CardBrand.amex;
    }
    if (RegExp(r'^6(?:011|5)').hasMatch(digits)) {
      return CardBrand.discover;
    }
    // Mastercard: the classic 51–55 range plus the 2221–2720 range added in 2017.
    if (RegExp(r'^5[1-5]').hasMatch(digits)) {
      return CardBrand.mastercard;
    }
    if (digits.length >= 4) {
      final int prefix = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (prefix >= 2221 && prefix <= 2720) {
        return CardBrand.mastercard;
      }
    } else if (digits.startsWith('2')) {
      // Too short to tell yet; treat as unknown rather than guessing wrong.
      return CardBrand.unknown;
    }
    return CardBrand.unknown;
  }

  /// How many digits this brand's numbers carry.
  static int expectedLength(CardBrand brand) =>
      brand == CardBrand.amex ? 15 : 16;

  /// How many digits the security code carries.
  static int cvcLength(CardBrand brand) => brand == CardBrand.amex ? 4 : 3;

  /// The Luhn checksum every card number satisfies.
  static bool passesLuhn(String number) {
    final String digits = digitsOf(number);
    if (digits.length < 12) {
      return false;
    }
    int sum = 0;
    bool doubling = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int value = digits.codeUnitAt(i) - 48;
      if (doubling) {
        value *= 2;
        if (value > 9) {
          value -= 9;
        }
      }
      sum += value;
      doubling = !doubling;
    }
    return sum % 10 == 0;
  }

  /// Returns a catalog key when the number is unusable, null when it is fine.
  static String? validateNumber(String number) {
    final String digits = digitsOf(number);
    final CardBrand brand = brandOf(digits);
    if (digits.length != expectedLength(brand) || !passesLuhn(digits)) {
      return 'invalidCard';
    }
    if (!brand.isAccepted) {
      return 'cardBrandNotAccepted';
    }
    return null;
  }

  /// `4242 4242 4242 4242`, or `3782 822463 10005` for Amex.
  static String formatNumber(String number) {
    final String digits = digitsOf(number);
    final List<int> groups = brandOf(digits) == CardBrand.amex
        ? <int>[4, 6, 5]
        : <int>[4, 4, 4, 4];
    final StringBuffer buffer = StringBuffer();
    int index = 0;
    for (final int size in groups) {
      if (index >= digits.length) {
        break;
      }
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      final int end = index + size;
      buffer.write(digits.substring(index, end > digits.length ? digits.length : end));
      index = end;
    }
    return buffer.toString();
  }

  static String last4(String number) {
    final String digits = digitsOf(number);
    return digits.length < 4 ? digits : digits.substring(digits.length - 4);
  }

  /// `•••• 4242` — what a receipt or a saved card shows.
  static String mask(String last4) => '•••• $last4';

  /// Parses `MM/YY` or `MMYY` into (month, year). Year is returned in full.
  static (int month, int year)? parseExpiry(String input) {
    final String digits = digitsOf(input);
    if (digits.length != 4) {
      return null;
    }
    final int month = int.parse(digits.substring(0, 2));
    final int year = 2000 + int.parse(digits.substring(2));
    if (month < 1 || month > 12) {
      return null;
    }
    return (month, year);
  }

  /// Returns a catalog key when the expiry is missing, malformed or past.
  ///
  /// [now] is injectable so the check is testable without freezing the clock.
  static String? validateExpiry(String input, {DateTime? now}) {
    final (int, int)? parsed = parseExpiry(input);
    if (parsed == null) {
      return 'invalidExpiry';
    }
    final (int month, int year) = parsed;
    final DateTime today = now ?? DateTime.now();
    // A card is valid through the last day of its expiry month.
    final DateTime expiresAfter = DateTime(year, month + 1);
    return expiresAfter.isAfter(DateTime(today.year, today.month, today.day))
        ? null
        : 'cardExpired';
  }

  static String formatExpiry(String input) {
    final String digits = digitsOf(input);
    if (digits.length <= 2) {
      return digits;
    }
    return '${digits.substring(0, 2)}/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
  }

  static String? validateCvc(String cvc, CardBrand brand) =>
      digitsOf(cvc).length == cvcLength(brand) ? null : 'invalidCvc';

  static String? validateHolder(String name) =>
      name.trim().length >= 3 ? null : 'cardHolderRequired';
}

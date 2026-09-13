/// Form validation. Every method returns a catalog key on failure and null on
/// success, so the view can localize the message it shows.
abstract final class Validators {
  static String? email(String value) {
    final String trimmed = value.trim();
    final bool looksValid = RegExp(
      r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
    ).hasMatch(trimmed);
    return looksValid ? null : 'invalidEmail';
  }

  static String? password(String value) =>
      value.length >= 8 ? null : 'passwordTooShort';

  static String? match(String a, String b) =>
      a == b ? null : 'passwordsDontMatch';

  static String? name(String value) =>
      value.trim().length >= 2 ? null : 'nameRequired';

  /// Haitian mobile numbers are 8 digits and start with 2, 3 or 4, optionally
  /// prefixed with the +509 country code.
  static String? haitianPhone(String value) {
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final String local =
        digits.startsWith('509') ? digits.substring(3) : digits;
    final bool valid =
        local.length == 8 && RegExp(r'^[234]').hasMatch(local);
    return valid ? null : 'invalidPhone';
  }

  static String normalizeHaitianPhone(String value) {
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final String local =
        digits.startsWith('509') ? digits.substring(3) : digits;
    return '+509$local';
  }

  static String? notEmpty(String value) =>
      value.trim().isEmpty ? 'required' : null;
}

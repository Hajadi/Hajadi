import 'package:flutter_test/flutter_test.dart';
import 'package:jwenn_met/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts ordinary addresses', () {
      expect(Validators.email('marie@jwennmet.ht'), isNull);
      expect(Validators.email(' bos.ayiti+work@mail.co '), isNull);
    });

    test('rejects malformed addresses with a catalog key', () {
      expect(Validators.email('marie'), 'invalidEmail');
      expect(Validators.email('marie@'), 'invalidEmail');
      expect(Validators.email(''), 'invalidEmail');
    });
  });

  group('haitianPhone', () {
    test('accepts 8-digit mobile numbers with or without the country code', () {
      expect(Validators.haitianPhone('37120045'), isNull);
      expect(Validators.haitianPhone('+509 37 12 00 45'), isNull);
      expect(Validators.haitianPhone('50944112233'), isNull);
      expect(Validators.haitianPhone('28110000'), isNull);
    });

    test('rejects wrong length or leading digit', () {
      expect(Validators.haitianPhone('3712004'), 'invalidPhone');
      expect(Validators.haitianPhone('571200450'), 'invalidPhone');
      expect(Validators.haitianPhone('97120045'), 'invalidPhone');
    });

    test('normalizes to +509 E.164', () {
      expect(Validators.normalizeHaitianPhone('37 12 00 45'), '+50937120045');
      expect(
        Validators.normalizeHaitianPhone('+509-3712-0045'),
        '+50937120045',
      );
    });
  });

  test('password and confirmation', () {
    expect(Validators.password('short'), 'passwordTooShort');
    expect(Validators.password('demo1234'), isNull);
    expect(Validators.match('demo1234', 'demo1234'), isNull);
    expect(Validators.match('demo1234', 'demo12345'), 'passwordsDontMatch');
  });
}

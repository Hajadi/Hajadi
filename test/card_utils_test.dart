import 'package:flutter_test/flutter_test.dart';
import 'package:jwenn_met/core/utils/card_utils.dart';
import 'package:jwenn_met/models/invoice.dart';
import 'package:jwenn_met/models/job_request.dart';
import 'package:jwenn_met/services/payment_service.dart';

void main() {
  group('brand detection', () {
    test('recognises Visa and both Mastercard ranges', () {
      expect(CardUtils.brandOf('4242424242424242'), CardBrand.visa);
      expect(CardUtils.brandOf('5555 5555 5555 4444'), CardBrand.mastercard);
      // 2221–2720 was added to Mastercard's range in 2017.
      expect(CardUtils.brandOf('2223003122003222'), CardBrand.mastercard);
      expect(CardUtils.brandOf('2720999999999999'), CardBrand.mastercard);
      expect(CardUtils.brandOf('2721999999999999'), CardBrand.unknown);
    });

    test('the accepted set is exactly Visa and Mastercard', () {
      expect(
        CardBrand.values.where((CardBrand b) => b.isAccepted).toSet(),
        <CardBrand>{CardBrand.visa, CardBrand.mastercard},
      );
    });

    test('recognises brands we do not accept', () {
      expect(CardUtils.brandOf('378282246310005'), CardBrand.amex);
      expect(CardUtils.brandOf('6011111111111117'), CardBrand.discover);
      expect(CardBrand.amex.isAccepted, isFalse);
      expect(CardBrand.visa.isAccepted, isTrue);
      expect(CardBrand.mastercard.isAccepted, isTrue);
    });

    test('does not guess from a single digit', () {
      expect(CardUtils.brandOf('2'), CardBrand.unknown);
      expect(CardUtils.brandOf(''), CardBrand.unknown);
    });
  });

  group('Luhn', () {
    test('accepts valid numbers and rejects a transposed digit', () {
      expect(CardUtils.passesLuhn('4242424242424242'), isTrue);
      expect(CardUtils.passesLuhn('5555555555554444'), isTrue);
      expect(CardUtils.passesLuhn('4242424242424243'), isFalse);
      expect(CardUtils.passesLuhn('4242'), isFalse);
    });
  });

  group('validateNumber', () {
    test('passes an accepted brand that checksums', () {
      expect(CardUtils.validateNumber('4242 4242 4242 4242'), isNull);
      expect(CardUtils.validateNumber('5555555555554444'), isNull);
    });

    test('flags a bad checksum before the brand', () {
      expect(CardUtils.validateNumber('4242424242424243'), 'invalidCard');
    });

    test('flags an unsupported brand distinctly', () {
      expect(
        CardUtils.validateNumber('378282246310005'),
        'cardBrandNotAccepted',
      );
    });

    test('flags a number of the wrong length', () {
      expect(CardUtils.validateNumber('424242424242'), 'invalidCard');
    });
  });

  group('expiry', () {
    final DateTime now = DateTime(2026, 9, 13);

    test('parses MM/YY and MMYY alike', () {
      expect(CardUtils.parseExpiry('09/28'), (9, 2028));
      expect(CardUtils.parseExpiry('0928'), (9, 2028));
      expect(CardUtils.parseExpiry('13/28'), isNull);
      expect(CardUtils.parseExpiry('9/28'), isNull);
    });

    test('a card is valid through the last day of its expiry month', () {
      expect(CardUtils.validateExpiry('09/26', now: now), isNull);
      expect(CardUtils.validateExpiry('10/26', now: now), isNull);
      expect(CardUtils.validateExpiry('08/26', now: now), 'cardExpired');
      expect(CardUtils.validateExpiry('12/25', now: now), 'cardExpired');
    });

    test('rejects malformed input', () {
      expect(CardUtils.validateExpiry('', now: now), 'invalidExpiry');
      expect(CardUtils.validateExpiry('99/99', now: now), 'invalidExpiry');
    });
  });

  group('formatting', () {
    test('groups Visa and Mastercard in fours', () {
      expect(
        CardUtils.formatNumber('4242424242424242'),
        '4242 4242 4242 4242',
      );
      expect(CardUtils.formatNumber('42424'), '4242 4');
    });

    test('groups Amex 4-6-5', () {
      expect(CardUtils.formatNumber('378282246310005'), '3782 822463 10005');
    });

    test('expiry gains its slash as it is typed', () {
      expect(CardUtils.formatExpiry('0'), '0');
      expect(CardUtils.formatExpiry('09'), '09');
      expect(CardUtils.formatExpiry('092'), '09/2');
      expect(CardUtils.formatExpiry('0928'), '09/28');
    });

    test('masking keeps only the last four', () {
      expect(CardUtils.last4('4242424242424242'), '4242');
      expect(CardUtils.mask('4242'), '•••• 4242');
    });
  });

  group('cvc', () {
    test('three digits, four for Amex', () {
      expect(CardUtils.validateCvc('123', CardBrand.visa), isNull);
      expect(CardUtils.validateCvc('12', CardBrand.visa), 'invalidCvc');
      expect(CardUtils.validateCvc('1234', CardBrand.visa), 'invalidCvc');
      expect(CardUtils.validateCvc('1234', CardBrand.amex), isNull);
    });
  });

  group('CardDetails.validate', () {
    CardDetails details({
      String number = '4242424242424242',
      String expiry = '09/28',
      String cvc = '123',
      String holder = 'MARIE ANGE PROPHETE',
    }) =>
        CardDetails(
          number: number,
          expiry: expiry,
          cvc: cvc,
          holder: holder,
        );

    final DateTime now = DateTime(2026, 9, 13);

    test('accepts a complete card', () {
      expect(details().validate(now: now), isNull);
      expect(details().brand, CardBrand.visa);
      expect(details().last4, '4242');
    });

    test('reports the first problem, number first', () {
      expect(
        details(number: '1234', expiry: '01/20', cvc: '1').validate(now: now),
        'invalidCard',
      );
      expect(details(expiry: '01/20').validate(now: now), 'cardExpired');
      expect(details(cvc: '1').validate(now: now), 'invalidCvc');
      expect(details(holder: ' ').validate(now: now), 'cardHolderRequired');
    });
  });

  group('DemoPaymentService', () {
    const Invoice invoice = Invoice(
      id: 'i1',
      number: 'JM-2026-1000',
      jobId: 'j1',
      customerId: 'c1',
      customerName: 'Kliyan',
      workerId: 'w1',
      workerName: 'Bòs',
      subtotal: 4500,
      serviceFee: 450,
      method: PaymentMethod.card,
      status: PaymentStatus.unpaid,
    );

    test('a card payment settles and returns only brand and last four',
        () async {
      final PaymentIntent intent = await DemoPaymentService().charge(
        invoice: invoice,
        method: PaymentMethod.card,
        idToken: 'token',
        card: const CardDetails(
          number: '5555555555554444',
          expiry: '12/30',
          cvc: '123',
          holder: 'MARIE ANGE',
        ),
      );
      expect(intent.status, PaymentStatus.paid);
      expect(intent.cardBrand, CardBrand.mastercard);
      expect(intent.cardLast4, '4444');
      expect(intent.reference, startsWith('CARD-'));
    });

    test('an invalid card throws with a catalog key', () async {
      expect(
        () => DemoPaymentService().charge(
          invoice: invoice,
          method: PaymentMethod.card,
          idToken: 'token',
          card: const CardDetails(
            number: '378282246310005',
            expiry: '12/30',
            cvc: '1234',
            holder: 'MARIE ANGE',
          ),
        ),
        throwsA(
          isA<PaymentException>().having(
            (PaymentException e) => e.messageKey,
            'messageKey',
            'cardBrandNotAccepted',
          ),
        ),
      );
    });

    test('cash stays unpaid until the worker confirms', () async {
      final PaymentIntent intent = await DemoPaymentService().charge(
        invoice: invoice,
        method: PaymentMethod.cash,
        idToken: 'token',
      );
      expect(intent.status, PaymentStatus.unpaid);
    });
  });

  group('PaymentMethod', () {
    test('parses card and keeps unknown values on the default', () {
      expect(PaymentMethod.fromId('card'), PaymentMethod.card);
      expect(PaymentMethod.fromId('bitcoin'), PaymentMethod.moncash);
    });

    test('knows which methods are electronic and which need a phone', () {
      expect(PaymentMethod.card.isElectronic, isTrue);
      expect(PaymentMethod.cash.isElectronic, isFalse);
      expect(PaymentMethod.card.needsPayerPhone, isFalse);
      expect(PaymentMethod.moncash.needsPayerPhone, isTrue);
      expect(PaymentMethod.natcash.needsPayerPhone, isTrue);
    });
  });
}

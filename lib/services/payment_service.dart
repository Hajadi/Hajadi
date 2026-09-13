import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/utils/card_utils.dart';
import '../models/invoice.dart';
import '../models/job_request.dart';

/// Card data as typed by the customer.
///
/// This object never leaves the device intact: [PaymentService] exchanges it
/// for a single-use token with the payment provider, and only that token is
/// sent to our own backend. Keeping the PAN out of Firestore and out of Cloud
/// Functions is what keeps Jwenn Mèt out of PCI DSS scope.
class CardDetails {
  const CardDetails({
    required this.number,
    required this.expiry,
    required this.cvc,
    required this.holder,
  });

  final String number;

  /// `MM/YY` as typed.
  final String expiry;
  final String cvc;
  final String holder;

  CardBrand get brand => CardUtils.brandOf(number);
  String get last4 => CardUtils.last4(number);

  /// Returns the first failing catalog key, or null when the card is usable.
  String? validate({DateTime? now}) =>
      CardUtils.validateNumber(number) ??
      CardUtils.validateExpiry(expiry, now: now) ??
      CardUtils.validateCvc(cvc, brand) ??
      CardUtils.validateHolder(holder);
}

/// A single-use handle for a card, returned by the provider's tokenization
/// endpoint. Safe to send to our backend and to log.
class CardToken {
  const CardToken({
    required this.token,
    required this.brand,
    required this.last4,
  });

  final String token;
  final CardBrand brand;
  final String last4;
}

/// Result of asking a provider to charge the customer.
class PaymentIntent {
  const PaymentIntent({
    required this.reference,
    required this.status,
    this.redirectUrl,
    this.message,
    this.cardBrand,
    this.cardLast4,
  });

  final String reference;
  final PaymentStatus status;

  /// Set when the payment finishes somewhere else: the wallet's hosted page,
  /// or a 3-D Secure challenge from the card issuer. The caller must open it
  /// and wait for the provider webhook to settle the invoice.
  final String? redirectUrl;
  final String? message;

  /// Echoed back for the receipt — never the full number.
  final CardBrand? cardBrand;
  final String? cardLast4;
}

/// Mobile money, cards and cash.
///
/// Wallet and acquirer credentials never reach the device: the app calls a
/// Cloud Function which holds the MonCash / NatCash / card-acquirer keys,
/// creates the payment, and receives the provider webhook that marks the
/// invoice paid.
abstract class PaymentService {
  Future<PaymentIntent> charge({
    required Invoice invoice,
    required PaymentMethod method,
    required String idToken,
    String payerPhone = '',
    CardDetails? card,
  });
}

class HttpPaymentService implements PaymentService {
  HttpPaymentService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.paymentsBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<PaymentIntent> charge({
    required Invoice invoice,
    required PaymentMethod method,
    required String idToken,
    String payerPhone = '',
    CardDetails? card,
  }) async {
    // Cash is settled in person: the invoice stays unpaid until the worker
    // confirms receipt, which keeps the ledger honest for both sides.
    if (method == PaymentMethod.cash) {
      return PaymentIntent(
        reference: 'CASH-${invoice.number}',
        status: PaymentStatus.unpaid,
      );
    }

    CardToken? token;
    if (method == PaymentMethod.card) {
      if (card == null) {
        throw const PaymentException('card_required');
      }
      final String? invalid = card.validate();
      if (invalid != null) {
        throw PaymentException(invalid);
      }
      // Tokenize first, so the number goes to the provider and nowhere else.
      token = await tokenizeCard(card);
    }

    final http.Response response = await _client.post(
      Uri.parse('$_baseUrl/createPayment'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(<String, dynamic>{
        'invoiceId': invoice.id,
        'jobId': invoice.jobId,
        'amount': invoice.total,
        'currency': invoice.currency,
        'method': method.id,
        if (method.needsPayerPhone) 'payerPhone': payerPhone,
        if (token != null) ...<String, dynamic>{
          'cardToken': token.token,
          'cardBrand': token.brand.id,
          'cardLast4': token.last4,
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw PaymentException(
        'provider_error',
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    return PaymentIntent(
      reference: '${body['reference'] ?? ''}',
      status: PaymentStatus.fromId('${body['status'] ?? 'processing'}'),
      redirectUrl: body['redirectUrl'] as String?,
      message: body['message'] as String?,
      cardBrand: token?.brand ??
          (body['cardBrand'] == null
              ? null
              : CardBrand.fromId('${body['cardBrand']}')),
      cardLast4: token?.last4 ?? body['cardLast4'] as String?,
    );
  }

  /// Exchanges card details for a single-use token, talking to the payment
  /// provider directly with the publishable key.
  ///
  /// The request shape below is the common one (Stripe, Checkout.com and
  /// most acquirers accept these field names); adjust it to whichever
  /// provider the merchant account is with. When no tokenization endpoint is
  /// configured, the card falls back to the hosted checkout page the Cloud
  /// Function returns — in that case no card data leaves this device at all.
  Future<CardToken?> tokenizeCard(CardDetails card) async {
    if (AppConfig.cardTokenizationUrl.isEmpty ||
        AppConfig.cardPublishableKey.isEmpty) {
      return null;
    }
    final (int, int)? expiry = CardUtils.parseExpiry(card.expiry);
    if (expiry == null) {
      throw const PaymentException('invalidExpiry');
    }

    final http.Response response = await _client.post(
      Uri.parse(AppConfig.cardTokenizationUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.cardPublishableKey}',
      },
      body: json.encode(<String, dynamic>{
        'type': 'card',
        'number': CardUtils.digitsOf(card.number),
        'expiry_month': expiry.$1,
        'expiry_year': expiry.$2,
        'cvc': CardUtils.digitsOf(card.cvc),
        'name': card.holder.trim(),
      }),
    );

    if (response.statusCode >= 400) {
      throw PaymentException(
        'card_declined',
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;
    final String? token = (body['token'] ?? body['id']) as String?;
    if (token == null) {
      throw const PaymentException('card_declined');
    }
    return CardToken(
      token: token,
      brand: card.brand,
      last4: card.last4,
    );
  }
}

/// Simulates every method so the payment screen is walkable in demo mode.
class DemoPaymentService implements PaymentService {
  @override
  Future<PaymentIntent> charge({
    required Invoice invoice,
    required PaymentMethod method,
    required String idToken,
    String payerPhone = '',
    CardDetails? card,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (method == PaymentMethod.cash) {
      return PaymentIntent(
        reference: 'CASH-${invoice.number}',
        status: PaymentStatus.unpaid,
      );
    }

    if (method == PaymentMethod.card) {
      if (card == null) {
        throw const PaymentException('card_required');
      }
      final String? invalid = card.validate();
      if (invalid != null) {
        throw PaymentException(invalid);
      }
      // A card ending 0000 declines, so the failure path is demonstrable.
      if (card.last4 == '0000') {
        throw const PaymentException('card_declined');
      }
      return PaymentIntent(
        reference: 'CARD-${DateTime.now().millisecondsSinceEpoch}',
        status: PaymentStatus.paid,
        cardBrand: card.brand,
        cardLast4: card.last4,
      );
    }

    return PaymentIntent(
      reference:
          '${method.id.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
      status: PaymentStatus.paid,
    );
  }
}

class PaymentException implements Exception {
  const PaymentException(this.code, [this.message]);

  /// Either a catalog key (card validation) or a provider code.
  final String code;
  final String? message;

  /// Catalog key to show the user for this failure.
  String get messageKey => switch (code) {
        'card_declined' => 'paymentFailed',
        'card_required' => 'invalidCard',
        'provider_error' => 'paymentFailed',
        _ => code,
      };

  @override
  String toString() => 'PaymentException($code, $message)';
}

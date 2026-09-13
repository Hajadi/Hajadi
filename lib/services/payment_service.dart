import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../models/invoice.dart';
import '../models/job_request.dart';

/// Result of asking a wallet to charge the customer.
class PaymentIntent {
  const PaymentIntent({
    required this.reference,
    required this.status,
    this.redirectUrl,
    this.message,
  });

  final String reference;
  final PaymentStatus status;

  /// MonCash and NatCash both complete in their own hosted page; when this is
  /// set the caller must open it and wait for the webhook to flip the invoice.
  final String? redirectUrl;
  final String? message;
}

/// Mobile-money and cash settlement.
///
/// Wallet credentials never reach the device: the app calls a Cloud Function
/// which holds the MonCash / NatCash merchant keys, creates the payment and
/// receives the provider webhook that marks the invoice paid.
abstract class PaymentService {
  Future<PaymentIntent> charge({
    required Invoice invoice,
    required PaymentMethod method,
    required String payerPhone,
    required String idToken,
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
    required String payerPhone,
    required String idToken,
  }) async {
    // Cash is settled in person: the invoice stays unpaid until the worker
    // confirms receipt, which keeps the ledger honest for both sides.
    if (method == PaymentMethod.cash) {
      return PaymentIntent(
        reference: 'CASH-${invoice.number}',
        status: PaymentStatus.unpaid,
      );
    }

    final Uri uri = Uri.parse('$_baseUrl/createPayment');
    final http.Response response = await _client.post(
      uri,
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
        'payerPhone': payerPhone,
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
    );
  }
}

/// Simulates both wallets so the payment screen is walkable in demo mode.
class DemoPaymentService implements PaymentService {
  @override
  Future<PaymentIntent> charge({
    required Invoice invoice,
    required PaymentMethod method,
    required String payerPhone,
    required String idToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (method == PaymentMethod.cash) {
      return PaymentIntent(
        reference: 'CASH-${invoice.number}',
        status: PaymentStatus.unpaid,
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

  final String code;
  final String? message;

  @override
  String toString() => 'PaymentException($code, $message)';
}

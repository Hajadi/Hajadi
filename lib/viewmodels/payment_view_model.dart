import 'dart:async';

import '../models/invoice.dart';
import '../models/job_request.dart';
import '../services/payment_service.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Pays one invoice, and lists the payment history for either side.
class PaymentViewModel extends BaseViewModel {
  PaymentViewModel(this._services);

  final Services _services;

  PaymentIntent? _intent;
  PaymentIntent? get intent => _intent;

  Stream<List<Invoice>> historyFor(String userId, {required bool asWorker}) =>
      asWorker
          ? _services.data.watchInvoicesForWorker(userId)
          : _services.data.watchInvoicesForCustomer(userId);

  /// Charges the wallet, then reflects the outcome on the invoice.
  ///
  /// Cash stays `unpaid` until the worker confirms they were handed the money;
  /// wallet payments that need a hosted page come back `processing` and are
  /// settled by the provider webhook.
  Future<PaymentIntent?> pay({
    required Invoice invoice,
    required PaymentMethod method,
    required String payerPhone,
  }) async {
    final PaymentIntent? intent = await guard<PaymentIntent>(() async {
      // The function verifies this token before touching the wallet APIs.
      final String token = await _services.auth.idToken() ?? '';
      final PaymentIntent result = await _services.payments.charge(
        invoice: invoice,
        method: method,
        payerPhone: payerPhone,
        idToken: token,
      );
      if (result.status != PaymentStatus.unpaid) {
        await _services.data.updateInvoiceStatus(
          invoice.id,
          result.status,
          transactionRef: result.reference,
        );
      }
      return result;
    }, errorKey: 'paymentFailed');
    _intent = intent;
    safeNotify();
    return intent;
  }

  /// The worker acknowledging cash in hand.
  Future<void> confirmCashReceived(Invoice invoice) async {
    await guard(() async {
      await _services.data.updateInvoiceStatus(
        invoice.id,
        PaymentStatus.paid,
        transactionRef: invoice.transactionRef ?? 'CASH-${invoice.number}',
      );
      return true;
    }, errorKey: 'paymentFailed');
  }
}

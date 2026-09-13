import 'dart:async';

import 'package:flutter/foundation.dart';

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

  /// Charges the chosen method, then reflects the outcome on the invoice.
  ///
  /// Cash stays `unpaid` until the worker confirms they were handed the money.
  /// Wallet and card payments that need a hosted page (or a 3-D Secure
  /// challenge) come back `processing` and are settled by the provider
  /// webhook, never by the client's word for it.
  ///
  /// [card] is only read for [PaymentMethod.card]; it is exchanged for a
  /// single-use token inside the service and never reaches our backend.
  Future<PaymentIntent?> pay({
    required Invoice invoice,
    required PaymentMethod method,
    String payerPhone = '',
    CardDetails? card,
  }) async {
    setBusy(true);
    setError(null);
    try {
      // The function verifies this token before touching any provider API.
      final String token = await _services.auth.idToken() ?? '';
      final PaymentIntent result = await _services.payments.charge(
        invoice: invoice,
        method: method,
        idToken: token,
        payerPhone: payerPhone,
        card: card,
      );

      if (result.status != PaymentStatus.unpaid) {
        await _services.data.updateInvoiceStatus(
          invoice.id,
          result.status,
          method: method,
          transactionRef: result.reference,
          cardBrand: result.cardBrand?.id,
          cardLast4: result.cardLast4,
        );
      }
      _intent = result;
      return result;
    } on PaymentException catch (error) {
      // Card validation failures carry a catalog key; provider failures fall
      // back to the generic payment message.
      debugPrint('payment failed: $error');
      setError(error.messageKey);
      return null;
    } catch (error, stack) {
      debugPrint('payment failed: $error\n$stack');
      setError('paymentFailed');
      return null;
    } finally {
      setBusy(false);
      safeNotify();
    }
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

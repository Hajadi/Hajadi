import 'package:flutter/material.dart';

import '../../models/job_request.dart';
import '../localization/strings.dart';

/// One place that maps a payment method to its label and icon.
///
/// Four screens used to carry their own copy of this switch, which is exactly
/// how a new method ends up half-supported.
extension PaymentMethodPresentation on PaymentMethod {
  String label(Strings s) => switch (this) {
        PaymentMethod.moncash => s.moncash,
        PaymentMethod.natcash => s.natcash,
        PaymentMethod.card => s.card,
        PaymentMethod.cash => s.cash,
      };

  IconData get icon => switch (this) {
        PaymentMethod.moncash => Icons.account_balance_wallet_outlined,
        PaymentMethod.natcash => Icons.account_balance_wallet_outlined,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.cash => Icons.payments_outlined,
      };
}

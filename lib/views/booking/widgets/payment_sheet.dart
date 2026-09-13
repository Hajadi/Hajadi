import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../models/invoice.dart';
import '../../../models/job_request.dart';
import '../../../services/payment_service.dart';
import '../../../viewmodels/payment_view_model.dart';
import '../../../viewmodels/session_view_model.dart';

/// MonCash / NatCash / cash checkout for one invoice.
Future<void> showPaymentSheet(
  BuildContext context, {
  required Invoice invoice,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _PaymentSheet(invoice: invoice),
      ),
    );

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.invoice});

  final Invoice invoice;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late PaymentMethod _method = widget.invoice.method;
  late final TextEditingController _phone = TextEditingController(
    text: context.read<SessionViewModel>().user?.phone ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String _label(Strings s, PaymentMethod method) => switch (method) {
        PaymentMethod.moncash => s.moncash,
        PaymentMethod.natcash => s.natcash,
        PaymentMethod.cash => s.cash,
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(s.payWith, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: <Widget>[
                  _Line(
                    label: s.subtotal,
                    value: Formatters.money(widget.invoice.subtotal, localeCode),
                  ),
                  _Line(
                    label: s.serviceFee,
                    value:
                        Formatters.money(widget.invoice.serviceFee, localeCode),
                  ),
                  const Divider(),
                  _Line(
                    label: s.total,
                    value: Formatters.money(widget.invoice.total, localeCode),
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final PaymentMethod method in PaymentMethod.values)
                  ChoiceChip(
                    label: Text(_label(s, method)),
                    selected: _method == method,
                    onSelected: (_) => setState(() => _method = method),
                  ),
              ],
            ),
            if (_method != PaymentMethod.cash) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: s.phoneForPayment,
                  prefixIcon: const Icon(Icons.smartphone_rounded),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            BusyButton(
              label: _method == PaymentMethod.cash ? s.confirm : s.payNow,
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                final PaymentViewModel payments =
                    context.read<PaymentViewModel>();
                final PaymentIntent? intent = await payments.pay(
                  invoice: widget.invoice,
                  method: _method,
                  payerPhone: _phone.text.trim(),
                );
                if (!context.mounted) {
                  return;
                }
                setState(() => _busy = false);

                // A hosted checkout page finishes the payment outside the app;
                // the provider webhook is what marks the invoice paid.
                final String? redirect = intent?.redirectUrl;
                if (redirect != null && redirect.isNotEmpty) {
                  await launchUrl(
                    Uri.parse(redirect),
                    mode: LaunchMode.externalApplication,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  return;
                }

                Navigator.of(context).pop();
                showAppSnackBar(
                  context,
                  intent == null
                      ? s.paymentFailed
                      : (_method == PaymentMethod.cash
                          ? s.requestSentBody
                          : s.paymentSuccess),
                  error: intent == null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: strong
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: strong
                ? theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

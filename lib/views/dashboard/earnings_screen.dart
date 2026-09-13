import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/card_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/card_brand_mark.dart';
import '../../core/widgets/common.dart';
import '../../models/invoice.dart';
import '../../viewmodels/payment_view_model.dart';
import '../../viewmodels/session_view_model.dart';

/// Invoice history — the same screen serves a worker's payouts and a
/// customer's payments, since both read the same ledger from their own side.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();
    final PaymentViewModel payments = context.read<PaymentViewModel>();
    final String localeCode = Localizations.localeOf(context).languageCode;
    final String? userId = session.user?.id;
    final bool asWorker = session.isWorker;

    if (userId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: Text(asWorker ? s.earnings : s.paymentHistory)),
      body: StreamBuilder<List<Invoice>>(
        stream: payments.historyFor(userId, asWorker: asWorker),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<Invoice>> snapshot,
        ) {
          if (!snapshot.hasData) {
            return const LoadingList(height: 80);
          }
          final List<Invoice> invoices = snapshot.data!;
          if (invoices.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: s.noRequests,
            );
          }
          final double paidTotal = invoices
              .where((Invoice invoice) => invoice.status == PaymentStatus.paid)
              .fold<double>(
                0,
                (double sum, Invoice invoice) =>
                    sum + (asWorker ? invoice.workerPayout : invoice.total),
              );

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: invoices.length + 1,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        asWorker ? s.earningsTotal : s.total,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        Formatters.money(paidTotal, localeCode),
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                );
              }
              final Invoice invoice = invoices[index - 1];
              return AppCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.invoiceNumber(number: invoice.number),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${asWorker ? invoice.customerName : invoice.workerName}'
                            ' · ${Formatters.date(invoice.issuedAt, localeCode)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (invoice.cardLast4 != null) ...<Widget>[
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                CardBrandMark(
                                  brand: CardBrand.fromId(invoice.cardBrand),
                                  height: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  CardUtils.mask(invoice.cardLast4!),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          Formatters.money(
                            asWorker ? invoice.workerPayout : invoice.total,
                            localeCode,
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        StatusPill(
                          label: invoice.status == PaymentStatus.paid
                              ? s.paid
                              : s.unpaid,
                          color: invoice.status == PaymentStatus.paid
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

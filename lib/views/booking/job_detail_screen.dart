import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/invoice.dart';
import '../../models/job_request.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../viewmodels/jobs_view_model.dart';
import '../../viewmodels/payment_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../common/report_sheet.dart';
import 'jobs_screen.dart';
import 'widgets/payment_sheet.dart';

/// One job, with every action its current status allows.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final JobsViewModel jobs = context.watch<JobsViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();
    final bool asWorker = session.isWorker;

    final Iterable<JobRequest> matches =
        jobs.jobs.where((JobRequest job) => job.id == jobId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: jobs.loading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(icon: Icons.assignment_outlined, title: s.noRequests),
      );
    }
    final JobRequest job = matches.first;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ThemeData theme = Theme.of(context);
    final ServiceCategory? category = ServiceCategory.fromId(job.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.bookingTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.reportUser,
            onPressed: () => showReportSheet(
              context,
              targetUserId: asWorker ? job.customerId : job.workerId,
              targetName: asWorker ? job.customerName : job.workerName,
              jobId: job.id,
            ),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AppAvatar(
                      name: asWorker ? job.customerName : job.workerName,
                      photoUrl:
                          asWorker ? job.customerPhotoUrl : job.workerPhotoUrl,
                      radius: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            asWorker ? job.customerName : job.workerName,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            category?.label(s) ?? '',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: JobCard.statusLabel(s, job.status),
                      color: JobCard.statusColor(job.status),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                Text(job.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                _Row(
                  icon: Icons.event_outlined,
                  label: s.preferredDate,
                  value: Formatters.dateTime(job.scheduledAt, localeCode),
                ),
                _Row(
                  icon: Icons.place_outlined,
                  label: s.jobLocation,
                  value: <String>[
                    if (job.addressNote.isNotEmpty) job.addressNote,
                    if (job.city != null) job.city!,
                  ].join(' · '),
                ),
                _Row(
                  icon: Icons.payments_outlined,
                  label: s.budget,
                  value: Formatters.money(job.billableAmount, localeCode),
                ),
                _Row(
                  icon: Icons.account_balance_wallet_outlined,
                  label: s.paymentMethod,
                  value: switch (job.paymentMethod) {
                    PaymentMethod.moncash => s.moncash,
                    PaymentMethod.natcash => s.natcash,
                    PaymentMethod.cash => s.cash,
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _InvoiceSection(job: job, asWorker: asWorker),
          const SizedBox(height: AppSpacing.md),
          // Chat rather than a call: a written thread stays attached to the
          // job, which matters when the two sides disagree later.
          OutlinedButton.icon(
            onPressed: () async {
              if (session.user == null) {
                return;
              }
              final String? conversationId =
                  await context.read<ConversationsViewModel>().openWith(
                        me: session.user!,
                        otherId: asWorker ? job.customerId : job.workerId,
                        otherName:
                            asWorker ? job.customerName : job.workerName,
                        otherPhotoUrl: asWorker
                            ? job.customerPhotoUrl
                            : job.workerPhotoUrl,
                        jobId: job.id,
                      );
              if (conversationId != null && context.mounted) {
                context.push(Routes.chatThread(conversationId));
              }
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            label: Text(s.message),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: _Actions(job: job, asWorker: asWorker),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value.isEmpty ? '—' : value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

/// Invoice card — appears as soon as the worker marks the job complete.
class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.job, required this.asWorker});

  final JobRequest job;
  final bool asWorker;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();
    final PaymentViewModel payments = context.read<PaymentViewModel>();
    final String? userId = session.user?.id;
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final String localeCode = Localizations.localeOf(context).languageCode;

    return StreamBuilder<List<Invoice>>(
      stream: payments.historyFor(userId, asWorker: asWorker),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Invoice>> snapshot,
      ) {
        final Iterable<Invoice> matches = (snapshot.data ?? <Invoice>[])
            .where((Invoice invoice) => invoice.jobId == job.id);
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }
        final Invoice invoice = matches.first;
        final ThemeData theme = Theme.of(context);

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.receipt_long_outlined, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      s.invoiceNumber(number: invoice.number),
                      style: theme.textTheme.titleMedium,
                    ),
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
              const Divider(height: AppSpacing.lg),
              _Row(
                icon: Icons.calculate_outlined,
                label: s.subtotal,
                value: Formatters.money(invoice.subtotal, localeCode),
              ),
              _Row(
                icon: Icons.percent_rounded,
                label: s.serviceFee,
                value: Formatters.money(invoice.serviceFee, localeCode),
              ),
              _Row(
                icon: Icons.summarize_outlined,
                label: s.total,
                value: Formatters.money(invoice.total, localeCode),
              ),
              if (!asWorker && invoice.status != PaymentStatus.paid)
                FilledButton.icon(
                  onPressed: () => showPaymentSheet(context, invoice: invoice),
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: Text(s.payNow),
                ),
              if (asWorker &&
                  invoice.status != PaymentStatus.paid &&
                  invoice.method == PaymentMethod.cash)
                OutlinedButton.icon(
                  onPressed: () => payments.confirmCashReceived(invoice),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text('${s.cash} · ${s.paid}'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.job, required this.asWorker});

  final JobRequest job;
  final bool asWorker;

  Future<double?> _askFinalPrice(BuildContext context) async {
    final Strings s = context.l10n;
    final TextEditingController controller =
        TextEditingController(text: job.billableAmount.toStringAsFixed(0));
    final double? value = await showDialog<double>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(s.markComplete),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '${s.amount} (${s.currency})',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              double.tryParse(controller.text) ?? job.billableAmount,
            ),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final JobsViewModel jobs = context.watch<JobsViewModel>();

    final List<Widget> actions = <Widget>[];

    if (asWorker) {
      if (job.status == JobStatus.pending) {
        actions.addAll(<Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => jobs.reject(job),
              child: Text(s.reject),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: () => jobs.accept(job),
              child: Text(s.accept),
            ),
          ),
        ]);
      } else if (job.status == JobStatus.accepted) {
        actions.add(
          Expanded(
            child: FilledButton(
              onPressed: () => jobs.start(job),
              child: Text(s.statusInProgress),
            ),
          ),
        );
      } else if (job.status == JobStatus.inProgress) {
        actions.add(
          Expanded(
            child: FilledButton(
              onPressed: () async {
                final double? price = await _askFinalPrice(context);
                if (price == null || !context.mounted) {
                  return;
                }
                final Invoice? invoice =
                    await jobs.complete(job, finalPrice: price);
                if (context.mounted && invoice != null) {
                  showAppSnackBar(
                    context,
                    s.invoiceNumber(number: invoice.number),
                  );
                }
              },
              child: Text(s.markComplete),
            ),
          ),
        );
      }
    } else {
      if (job.status.isOpen) {
        actions.add(
          Expanded(
            child: OutlinedButton(
              onPressed: () => jobs.cancel(job),
              child: Text(s.cancel),
            ),
          ),
        );
      }
      if (job.status == JobStatus.completed && job.reviewId == null) {
        actions.addAll(<Widget>[
          if (actions.isNotEmpty) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: () => context.push(Routes.review(job.id)),
              child: Text(s.writeReview),
            ),
          ),
        ]);
      }
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: actions),
      ),
    );
  }
}

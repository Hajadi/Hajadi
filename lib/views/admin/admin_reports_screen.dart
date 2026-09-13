import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../models/user_report.dart';
import '../../viewmodels/admin_view_model.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  String _reasonLabel(Strings s, ReportReason reason) => switch (reason) {
        ReportReason.spam => s.reportReasonSpam,
        ReportReason.fraud => s.reportReasonFraud,
        ReportReason.abuse => s.reportReasonAbuse,
        ReportReason.fake => s.reportReasonFake,
        ReportReason.other => s.reportReasonOther,
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AdminViewModel admin = context.watch<AdminViewModel>();
    final String localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(s.reportedContent)),
      body: admin.reports.isEmpty
          ? EmptyState(icon: Icons.flag_outlined, title: s.reports)
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: admin.reports.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final UserReport report = admin.reports[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              report.targetName.isEmpty
                                  ? report.targetUserId
                                  : report.targetName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusPill(
                            label: _reasonLabel(s, report.reason),
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        Formatters.dateTime(report.createdAt, localeCode),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (report.details.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          report.details,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => admin.resolveReport(
                                report.id,
                                dismissed: true,
                              ),
                              child: Text(s.reject),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => admin.resolveReport(
                                report.id,
                                dismissed: false,
                                note: 'resolved',
                              ),
                              child: Text(s.done),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

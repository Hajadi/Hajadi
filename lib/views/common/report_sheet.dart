import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/user_report.dart';
import '../../viewmodels/review_view_model.dart';
import '../../viewmodels/session_view_model.dart';

/// Reporting sheet, reachable from a worker profile, a chat thread and a
/// review. Reports land in the admin queue, never in public view.
Future<void> showReportSheet(
  BuildContext context, {
  required String targetUserId,
  required String targetName,
  String? jobId,
  String? reviewId,
}) async {
  final SessionViewModel session = context.read<SessionViewModel>();
  final String? reporterId = session.user?.id;
  if (reporterId == null) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _ReportSheet(
        reporterId: reporterId,
        targetUserId: targetUserId,
        targetName: targetName,
        jobId: jobId,
        reviewId: reviewId,
      ),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.reporterId,
    required this.targetUserId,
    required this.targetName,
    this.jobId,
    this.reviewId,
  });

  final String reporterId;
  final String targetUserId;
  final String targetName;
  final String? jobId;
  final String? reviewId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason _reason = ReportReason.fraud;
  final TextEditingController _details = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _label(Strings s, ReportReason reason) => switch (reason) {
        ReportReason.spam => s.reportReasonSpam,
        ReportReason.fraud => s.reportReasonFraud,
        ReportReason.abuse => s.reportReasonAbuse,
        ReportReason.fake => s.reportReasonFake,
        ReportReason.other => s.reportReasonOther,
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${s.reportTitle} · ${widget.targetName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final ReportReason reason in ReportReason.values)
              RadioListTile<ReportReason>(
                value: reason,
                groupValue: _reason,
                onChanged: (ReportReason? value) =>
                    setState(() => _reason = value ?? _reason),
                title: Text(_label(s, reason)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _details,
              maxLines: 3,
              decoration: InputDecoration(hintText: s.reasonHint),
            ),
            const SizedBox(height: AppSpacing.lg),
            BusyButton(
              label: s.submit,
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                final bool ok = await context.read<ReviewViewModel>().report(
                      reporterId: widget.reporterId,
                      targetUserId: widget.targetUserId,
                      targetName: widget.targetName,
                      reason: _reason,
                      details: _details.text,
                      jobId: widget.jobId,
                      reviewId: widget.reviewId,
                    );
                if (!context.mounted) {
                  return;
                }
                setState(() => _busy = false);
                Navigator.of(context).pop();
                showAppSnackBar(
                  context,
                  ok ? s.reportSubmitted : s.errorGeneric,
                  error: !ok,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

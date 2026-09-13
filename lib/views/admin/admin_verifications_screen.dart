import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/user_report.dart';
import '../../viewmodels/admin_view_model.dart';

class AdminVerificationsScreen extends StatelessWidget {
  const AdminVerificationsScreen({super.key});

  Future<bool?> _confirm(BuildContext context, String question) => showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          content: Text(question),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AdminViewModel admin = context.watch<AdminViewModel>();
    final String localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(s.pendingVerifications)),
      body: admin.verifications.isEmpty
          ? EmptyState(
              icon: Icons.verified_outlined,
              title: s.pendingVerifications,
              body: s.noNotifications,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: admin.verifications.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                final VerificationRequest request = admin.verifications[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          AppAvatar(name: request.workerName, radius: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  request.workerName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${request.idType.toUpperCase()} · '
                                  '${Formatters.date(request.submittedAt, localeCode)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(request.idDocumentUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(s.uploadId),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final bool? ok = await _confirm(
                                  context,
                                  s.rejectWorkerConfirm,
                                );
                                if (ok == true) {
                                  await admin.decideVerification(
                                    request.workerId,
                                    approved: false,
                                  );
                                }
                              },
                              child: Text(s.reject),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final bool? ok = await _confirm(
                                  context,
                                  s.approveWorkerConfirm,
                                );
                                if (ok == true) {
                                  await admin.decideVerification(
                                    request.workerId,
                                    approved: true,
                                  );
                                }
                              },
                              child: Text(s.approve),
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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// One tap to the national police line (114), behind a confirmation so it is
/// never dialled by accident from a pocket.
Future<void> confirmEmergencyCall(BuildContext context) async {
  final Strings s = context.l10n;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      icon: const Icon(Icons.emergency_rounded, color: AppColors.danger),
      title: Text(s.emergencyCall),
      content: Text('${s.emergencyConfirm}\n\n${AppConfig.emergencyNumber}'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.callNow),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final Uri uri = Uri(scheme: 'tel', path: AppConfig.emergencyNumber);
  if (!await launchUrl(uri) && context.mounted) {
    showAppSnackBar(context, s.errorGeneric, error: true);
  }
}

class EmergencyCallCard extends StatelessWidget {
  const EmergencyCallCard({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    return AppCard(
      onTap: () => confirmEmergencyCall(context),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: AppColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.emergency, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${s.emergencyCall} · ${AppConfig.emergencyNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

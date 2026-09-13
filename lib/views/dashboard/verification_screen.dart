import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/worker_dashboard_view_model.dart';

/// Identity verification: the worker uploads a government ID, an admin
/// decides, and only the resulting status is ever public.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _idDocument;
  final List<File> _certificates = <File>[];
  String _idType = 'cin';

  Future<void> _pickId() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _idDocument = File(picked.path));
    }
  }

  Future<void> _pickCertificate() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _certificates.add(File(picked.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final WorkerDashboardViewModel dashboard =
        context.watch<WorkerDashboardViewModel>();
    final WorkerProfile profile = dashboard.profile;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.idVerified)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                Icon(
                  profile.isVerified
                      ? Icons.verified_rounded
                      : Icons.badge_outlined,
                  color: profile.isVerified
                      ? AppColors.accent
                      : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    switch (profile.verification) {
                      VerificationStatus.approved => s.verificationApproved,
                      VerificationStatus.pending => s.verificationPending,
                      VerificationStatus.rejected => s.verificationRejected,
                      VerificationStatus.unverified => s.notVerified,
                    },
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(s.uploadId, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final (String id, String label) in <(String, String)>[
                ('cin', 'CIN'),
                ('nif', 'NIF'),
                ('passport', 'Passeport'),
                ('license', 'Permis'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _idType == id,
                  onSelected: (_) => setState(() => _idType = id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _UploadTile(
            icon: Icons.photo_camera_outlined,
            label: _idDocument == null
                ? s.uploadId
                : _idDocument!.path.split('/').last,
            onTap: _pickId,
            done: _idDocument != null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(s.certificates, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _UploadTile(
            icon: Icons.workspace_premium_outlined,
            label: s.uploadCertificate,
            onTap: _pickCertificate,
            done: _certificates.isNotEmpty,
          ),
          if (_certificates.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final File certificate in _certificates)
                  InputChip(
                    label: Text(certificate.path.split('/').last),
                    onDeleted: () =>
                        setState(() => _certificates.remove(certificate)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            // Plain language about where the document goes matters more than
            // legalese to someone handing over their ID.
            s.termsAgree,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BusyButton(
            label: s.submit,
            busy: dashboard.busy,
            onPressed: _idDocument == null
                ? null
                : () async {
                    final bool ok = await dashboard.submitVerification(
                      idDocument: _idDocument!,
                      idType: _idType,
                      certificates: _certificates,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    showAppSnackBar(
                      context,
                      ok ? s.verificationPending : s.errorGeneric,
                      error: !ok,
                    );
                  },
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.done,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.upload_rounded,
              color: done ? AppColors.accent : null,
            ),
          ],
        ),
      );
}

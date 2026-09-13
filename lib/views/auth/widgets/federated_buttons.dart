import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/auth_view_model.dart';

/// Google / Apple / phone sign-in, shared by the login and sign-up screens.
class FederatedButtons extends StatelessWidget {
  const FederatedButtons({super.key, required this.onDone});

  final VoidCallback onDone;

  bool get _showApple =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AuthViewModel auth = context.watch<AuthViewModel>();

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                s.orContinueWith,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: auth.busy
              ? null
              : () async {
                  final String? uid = await auth.signInWithGoogle();
                  if (uid != null) {
                    onDone();
                  }
                },
          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: Text(s.continueWithGoogle),
        ),
        if (_showApple) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    final String? uid = await auth.signInWithApple();
                    if (uid != null) {
                      onDone();
                    }
                  },
            icon: const Icon(Icons.apple_rounded, size: 24),
            label: Text(s.continueWithApple),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: auth.busy ? null : () => context.push(Routes.phone),
          icon: const Icon(Icons.smartphone_rounded, size: 22),
          label: Text(s.continueWithPhone),
        ),
      ],
    );
  }
}

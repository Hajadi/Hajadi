import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';

/// Shown while the session boots (restoring auth, language and theme).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(child: _SplashBody()),
      );
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    // Before a language is chosen the delegate may not be in place yet, so the
    // tagline falls back to the Kreyòl wording the brand leads with.
    final String tagline = Localizations.of<AppLocalizations>(
              context,
              AppLocalizations,
            ) !=
            null
        ? context.l10n.appTagline
        : 'Jwenn yon bòs ki gen konpetans toupre w';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const AppLogo(size: 96, vertical: true, onDark: true),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              tagline,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ),
        ],
      ),
    );
  }
}

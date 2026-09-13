import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../viewmodels/session_view_model.dart';

/// First screen of the app: the language choice that everything else honours.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  static const List<_LanguageOption> _options = <_LanguageOption>[
    _LanguageOption('ht', 'Kreyòl Ayisyen', 'Chwazi lang ou', '🇭🇹'),
    _LanguageOption('fr', 'Français', 'Choisissez votre langue', '🇫🇷'),
    _LanguageOption('en', 'English', 'Choose your language', '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();
    final String? current = session.locale?.languageCode;

    return Scaffold(
      appBar: showBackButton ? AppBar(title: Text(context.l10n.language)) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!showBackButton) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                const AppLogo(size: 64),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(
                'Chwazi lang ou · Choisissez votre langue · Choose your language',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ou ka chanje sa pi devan · Vous pourrez la changer plus tard',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (BuildContext context, int index) {
                    final _LanguageOption option = _options[index];
                    final bool selected = option.code == current;
                    return _LanguageCard(
                      option: option,
                      selected: selected,
                      onTap: () async {
                        await session.setLocale(Locale(option.code));
                        if (showBackButton && context.mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption(this.code, this.name, this.subtitle, this.flag);

  final String code;
  final String name;
  final String subtitle;
  final String flag;
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(option.flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(option.name, style: theme.textTheme.titleMedium),
                    Text(option.subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

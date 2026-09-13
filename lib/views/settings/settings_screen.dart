import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common.dart';
import '../../viewmodels/session_view_model.dart';
import '../onboarding/language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _languageName(String? code) => switch (code) {
        'fr' => 'Français',
        'en' => 'English',
        _ => 'Kreyòl Ayisyen',
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: <Widget>[
          _Group(
            title: s.account,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(s.language),
                subtitle: Text(_languageName(session.locale?.languageCode)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const LanguageScreen(showBackButton: true),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(s.theme),
                subtitle: Text(switch (session.themeMode) {
                  ThemeMode.light => s.themeLight,
                  ThemeMode.dark => s.themeDark,
                  ThemeMode.system => s.themeSystem,
                }),
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined, size: 18),
                      tooltip: s.themeLight,
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined, size: 18),
                      tooltip: s.themeDark,
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.smartphone_rounded, size: 18),
                      tooltip: s.themeSystem,
                    ),
                  ],
                  selected: <ThemeMode>{session.themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) =>
                      session.setThemeMode(selection.first),
                ),
              ),
            ],
          ),
          _Group(
            title: s.notifications,
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(s.pushNotifications),
                value: (session.user?.fcmTokens.isNotEmpty ?? false) ||
                    session.services.demoMode,
                onChanged: (bool value) => showAppSnackBar(
                  context,
                  value ? s.success : s.offline,
                ),
              ),
            ],
          ),
          _Group(
            title: s.help,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: Text(s.support),
                subtitle: const Text(AppConfig.supportEmail),
                onTap: () => launchUrl(
                  Uri(scheme: 'mailto', path: AppConfig.supportEmail),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: Text(s.privacy),
                onTap: () => launchUrl(
                  Uri.parse('https://jwennmet.ht/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(s.terms),
                onTap: () => launchUrl(
                  Uri.parse('https://jwennmet.ht/terms'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
          _Group(
            title: s.aboutApp,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    const AppLogo(size: 44),
                    const Spacer(),
                    Text(
                      s.version(version: AppConfig.appVersion),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  s.deleteAccount,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(s.deleteAccount),
                      content: Text(s.deleteAccountConfirm),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(s.cancel),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(s.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) {
                    return;
                  }
                  final bool done = await session.deleteAccount();
                  if (context.mounted && !done) {
                    showAppSnackBar(context, s.errorGeneric, error: true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(title: title),
          ...children,
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/app_user.dart';
import '../../viewmodels/session_view_model.dart';
import '../common/emergency_button.dart';

/// The "you" tab: identity, shortcuts, and the door to settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();
    final AppUser? user = session.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profile),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                AppAvatar(
                  name: user?.fullName ?? '',
                  photoUrl: user?.photoUrl,
                  radius: 30,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.fullName ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        user?.email ?? user?.phone ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (user?.city != null)
                        Text(
                          user!.city!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                if (session.isWorker)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(s.editProfile),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.dashboardProfile),
                  ),
                ListTile(
                  leading: const Icon(Icons.favorite_border_rounded),
                  title: Text(s.favorites),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.favorites),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: Text(s.notifications),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (session.unreadNotifications > 0)
                        Badge.count(count: session.unreadNotifications),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => context.push(Routes.notifications),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(s.paymentHistory),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.dashboardEarnings),
                ),
                if (session.isAdmin) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(s.adminDashboard),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(Routes.admin),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const EmergencyCallCard(),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  content: Text(s.signOutConfirm),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(s.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(s.logout),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await session.signOut();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(s.logout),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

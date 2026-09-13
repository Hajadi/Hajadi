import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/app_user.dart';
import '../../viewmodels/admin_view_model.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AdminViewModel admin = context.watch<AdminViewModel>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.users),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: s.workers),
              Tab(text: s.customers),
              Tab(text: s.users),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _UserList(users: admin.usersOfRole(UserRole.worker)),
            _UserList(users: admin.usersOfRole(UserRole.customer)),
            _UserList(users: admin.users),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users});

  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final AdminViewModel admin = context.read<AdminViewModel>();

    if (users.isEmpty) {
      return EmptyState(icon: Icons.group_outlined, title: s.users);
    }
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1, indent: 72),
      itemBuilder: (BuildContext context, int index) {
        final AppUser user = users[index];
        return ListTile(
          leading: AppAvatar(
            name: user.fullName,
            photoUrl: user.photoUrl,
            radius: 20,
          ),
          title: Text(user.fullName),
          subtitle: Text(
            <String>[
              user.email ?? user.phone ?? '',
              user.city ?? '',
            ].where((String part) => part.isNotEmpty).join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (user.isSuspended)
                StatusPill(
                  label: s.suspendUser,
                  color: Theme.of(context).colorScheme.error,
                ),
              PopupMenuButton<String>(
                onSelected: (String action) => admin.setUserSuspended(
                  user,
                  suspended: action == 'suspend',
                ),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  if (!user.isSuspended)
                    PopupMenuItem<String>(
                      value: 'suspend',
                      child: Text(s.suspendUser),
                    )
                  else
                    PopupMenuItem<String>(
                      value: 'reinstate',
                      child: Text(s.reinstateUser),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

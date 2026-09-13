import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../models/app_notification.dart';
import '../../viewmodels/notifications_view_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType type) => switch (type) {
        NotificationType.jobRequest => Icons.assignment_outlined,
        NotificationType.jobAccepted => Icons.check_circle_outline_rounded,
        NotificationType.jobRejected => Icons.cancel_outlined,
        NotificationType.message => Icons.chat_bubble_outline_rounded,
        NotificationType.review => Icons.star_outline_rounded,
        NotificationType.verification => Icons.verified_outlined,
        NotificationType.payment => Icons.payments_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final NotificationsViewModel model =
        context.watch<NotificationsViewModel>();
    final AppLocalizations l10n = context.l10nRaw;
    final String localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: <Widget>[
          if (model.unreadCount > 0)
            TextButton(
              onPressed: model.markAllRead,
              child: Text(s.markAllRead),
            ),
        ],
      ),
      body: model.loading
          ? const LoadingList(height: 64)
          : model.notifications.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: s.noNotifications,
                )
              : ListView.separated(
                  itemCount: model.notifications.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (BuildContext context, int index) {
                    final AppNotification notification =
                        model.notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: notification.read ? 0.06 : 0.14),
                        child: Icon(
                          _icon(notification.type),
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      // Stored as a catalog key + args, so it renders in
                      // whatever language is active right now.
                      title: Text(
                        l10n.sub(notification.messageKey, notification.args),
                        style: TextStyle(
                          fontWeight: notification.read
                              ? FontWeight.w400
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        Formatters.dateTime(notification.createdAt, localeCode),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {
                        final String? jobId = notification.jobId;
                        final String? conversationId =
                            notification.conversationId;
                        if (jobId != null) {
                          context.push(Routes.jobDetail(jobId));
                        } else if (conversationId != null) {
                          context.push(Routes.chatThread(conversationId));
                        }
                      },
                    );
                  },
                ),
    );
  }
}

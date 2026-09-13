import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/chat.dart';
import '../../viewmodels/chat_view_model.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final ConversationsViewModel model =
        context.watch<ConversationsViewModel>();
    final String localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(s.chats)),
      body: model.loading
          ? const LoadingList(height: 72)
          : model.conversations.isEmpty
              ? EmptyState(
                  icon: Icons.forum_outlined,
                  title: s.noChats,
                  actionLabel: s.search,
                  onAction: () => context.go(Routes.search),
                )
              : ListView.separated(
                  itemCount: model.conversations.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1, indent: 76),
                  itemBuilder: (BuildContext context, int index) {
                    final Conversation conversation =
                        model.conversations[index];
                    final int unread = conversation.unreadFor(model.userId);
                    return ListTile(
                      onTap: () =>
                          context.push(Routes.chatThread(conversation.id)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      leading: AppAvatar(
                        name: conversation.titleFor(model.userId),
                        photoUrl: conversation.photoFor(model.userId),
                        radius: 24,
                      ),
                      title: Text(
                        conversation.titleFor(model.userId),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        conversation.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            Formatters.time(
                              conversation.lastMessageAt,
                              localeCode,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          if (unread > 0)
                            Badge.count(count: unread)
                          else
                            const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

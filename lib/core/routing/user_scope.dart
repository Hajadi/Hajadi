import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/service_locator.dart';
import '../../viewmodels/admin_view_model.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../viewmodels/jobs_view_model.dart';
import '../../viewmodels/notifications_view_model.dart';
import '../../viewmodels/session_view_model.dart';
import '../../viewmodels/worker_dashboard_view_model.dart';

/// Provides the view-models that are scoped to the signed-in user.
///
/// They sit above the router (rather than inside each route) because the job
/// list, the inbox and the notification badge must survive tab switches — and
/// they are rebuilt from scratch, streams and all, whenever the identity or
/// role behind them changes.
class UserScope extends StatelessWidget {
  const UserScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();
    final Services services = session.services;
    final String? userId = session.user?.id;

    if (userId == null) {
      return child;
    }

    final bool isWorker = session.isWorker;
    final bool hasWorkerProfile = session.workerProfile != null;

    return MultiProvider(
      key: ValueKey<String>(
        '$userId:${session.user?.role.id}:$hasWorkerProfile',
      ),
      providers: [
        ChangeNotifierProvider<JobsViewModel>(
          create: (_) =>
              JobsViewModel(services, userId: userId, asWorker: isWorker),
        ),
        ChangeNotifierProvider<ConversationsViewModel>(
          create: (_) => ConversationsViewModel(services, userId),
        ),
        ChangeNotifierProvider<NotificationsViewModel>(
          create: (_) => NotificationsViewModel(services, userId),
        ),
        if (isWorker && hasWorkerProfile)
          ChangeNotifierProvider<WorkerDashboardViewModel>(
            create: (_) => WorkerDashboardViewModel(
              services,
              session.workerProfile!,
            ),
          ),
        if (session.isAdmin)
          ChangeNotifierProvider<AdminViewModel>(
            create: (_) => AdminViewModel(services, userId),
          ),
      ],
      child: child,
    );
  }
}

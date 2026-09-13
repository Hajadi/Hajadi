import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../viewmodels/session_view_model.dart';

/// Bottom-navigation shell. Workers get a dashboard where customers get a
/// search tab, so each side lands on the screen it actually lives in.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const List<String> _customerRoutes = <String>[
    Routes.home,
    Routes.search,
    Routes.jobs,
    Routes.chats,
    Routes.profile,
  ];

  static const List<String> _workerRoutes = <String>[
    Routes.dashboard,
    Routes.jobs,
    Routes.chats,
    Routes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final SessionViewModel session = context.watch<SessionViewModel>();
    final bool isWorker = session.isWorker;
    final List<String> routes = isWorker ? _workerRoutes : _customerRoutes;
    final String location = GoRouterState.of(context).uri.path;

    int index = routes.indexWhere(
      (String route) => location == route || location.startsWith('$route/'),
    );
    if (index < 0) {
      index = 0;
    }

    final List<NavigationDestination> destinations = <NavigationDestination>[
      if (isWorker)
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard_rounded),
          label: s.dashboard,
        )
      else ...<NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: s.appName,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search_rounded),
          label: s.search,
        ),
      ],
      NavigationDestination(
        icon: const Icon(Icons.assignment_outlined),
        selectedIcon: const Icon(Icons.assignment_rounded),
        label: isWorker ? s.pendingRequests : s.myRequests,
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: const Icon(Icons.chat_bubble_rounded),
        label: s.chats,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: const Icon(Icons.person_rounded),
        label: s.profile,
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, destinations.length - 1),
        destinations: destinations,
        onDestinationSelected: (int selected) => context.go(routes[selected]),
      ),
    );
  }
}

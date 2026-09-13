import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/worker_card.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/favorites_view_model.dart';
import '../../viewmodels/session_view_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final SessionViewModel session = context.read<SessionViewModel>();
    context
        .read<FavoritesViewModel>()
        .load(session.user?.favoriteWorkerIds ?? const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final FavoritesViewModel favorites = context.watch<FavoritesViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(s.favorites)),
      body: favorites.busy
          ? const LoadingList()
          : favorites.workers.isEmpty
              ? EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: s.noFavorites,
                  body: s.noFavoritesBody,
                  actionLabel: s.search,
                  onAction: () => context.go(Routes.search),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: favorites.workers.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (BuildContext context, int index) {
                    final WorkerProfile worker = favorites.workers[index];
                    return WorkerCard(
                      worker: worker,
                      isFavorite: session.isFavorite(worker.id),
                      onToggleFavorite: () async {
                        await session.toggleFavorite(worker.id);
                        _reload();
                      },
                      onTap: () =>
                          context.push(Routes.workerDetail(worker.id)),
                    );
                  },
                ),
    );
  }
}
